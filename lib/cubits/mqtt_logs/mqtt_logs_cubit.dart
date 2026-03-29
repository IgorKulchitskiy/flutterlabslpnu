import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class AlarmLogEntry {
  const AlarmLogEntry({
    required this.alarm,
    required this.state,
    required this.time,
    required this.raw,
  });

  final String alarm;
  final String state;
  final String time;
  final String raw;
}

class MqttLogsState {
  const MqttLogsState({
    this.logs = const <AlarmLogEntry>[],
    this.isConnected = false,
    this.isConnecting = true,
    this.statusMessage = 'Connecting...',
  });

  final List<AlarmLogEntry> logs;
  final bool isConnected;
  final bool isConnecting;
  final String statusMessage;

  MqttLogsState copyWith({
    List<AlarmLogEntry>? logs,
    bool? isConnected,
    bool? isConnecting,
    String? statusMessage,
  }) {
    return MqttLogsState(
      logs: logs ?? this.logs,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class MqttLogsCubit extends Cubit<MqttLogsState> {
  MqttLogsCubit() : super(const MqttLogsState());

  static const String broker = 'broker.emqx.io';
  static const int port = 1883;
  static const String topic = 'lpnu/igor/alarm/logs';

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
      _updatesSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final clientId =
        'flutter_alarm_viewer_${DateTime.now().millisecondsSinceEpoch}';
    final serverClient = MqttServerClient(broker, clientId)
      ..port = port
      ..keepAlivePeriod = 20
      ..logging(on: false)
      ..setProtocolV311()
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = (_) {}
      ..connectionMessage =
          MqttConnectMessage().withClientIdentifier(clientId).startClean();

    _client = serverClient;

    try {
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _client!.subscribe(topic, MqttQos.atMostOnce);

        _updatesSubscription = _client!.updates?.listen((events) {
          if (events.isEmpty) return;

          final recMess = events.first.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          _handleIncoming(payload);
        });
      } else {
        final returnCodeName =
            _client!.connectionStatus?.returnCode?.name ?? 'unknown';
        emit(
          state.copyWith(
            isConnected: false,
            isConnecting: false,
            statusMessage: 'Connect failed: $returnCodeName',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isConnected: false,
          isConnecting: false,
          statusMessage: 'Connect error: $e',
        ),
      );
    }
  }

  void _handleIncoming(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        _addLog(
          alarm: 'Unknown',
          stateText: 'UNKNOWN',
          time: DateTime.now().toString(),
          raw: payload,
        );
        return;
      }

      _addLog(
        alarm: decoded['alarm']?.toString() ?? 'Unknown',
        stateText: decoded['state']?.toString() ?? 'UNKNOWN',
        time: decoded['time']?.toString() ?? DateTime.now().toString(),
        raw: payload,
      );
    } catch (_) {
      _addLog(
        alarm: 'Parse error',
        stateText: 'INVALID',
        time: DateTime.now().toString(),
        raw: payload,
      );
    }
  }

  void _addLog({
    required String alarm,
    required String stateText,
    required String time,
    required String raw,
  }) {
    final updatedLogs = <AlarmLogEntry>[
      AlarmLogEntry(
        alarm: alarm,
        state: stateText,
        time: time,
        raw: raw,
      ),
      ...state.logs,
    ];

    if (updatedLogs.length > 200) {
      updatedLogs.removeRange(200, updatedLogs.length);
    }

    emit(state.copyWith(logs: updatedLogs));
  }

  void _onConnected() {
    emit(
      state.copyWith(
        isConnected: true,
        isConnecting: false,
        statusMessage: 'Connected',
      ),
    );
  }

  void _onDisconnected() {
    final returnCodeName =
        _client?.connectionStatus?.returnCode?.name ?? 'unknown';
    emit(
      state.copyWith(
        isConnected: false,
        isConnecting: false,
        statusMessage: 'Disconnected: $returnCodeName',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _updatesSubscription?.cancel();
    _client?.disconnect();
    return super.close();
  }
}
