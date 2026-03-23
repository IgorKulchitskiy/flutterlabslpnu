import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttLogsPage extends StatefulWidget {
  const MqttLogsPage({super.key});

  @override
  State<MqttLogsPage> createState() => _MqttLogsPageState();
}

class _MqttLogsPageState extends State<MqttLogsPage> {
  static const String _broker = 'broker.emqx.io';
  static const int _port = 1883;
  static const String _topic = 'lpnu/igor/alarm/logs';

  MqttClient? _client;

  final List<_AlarmLogEntry> _logs = [];
  bool _isConnected = false;
  bool _isConnecting = true;
  String _statusMessage = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initClient();
    _connectAndSubscribe();
  }

  void _initClient() {
    final clientId =
        'flutter_alarm_viewer_${DateTime.now().millisecondsSinceEpoch}';

    final serverClient = MqttServerClient(_broker, clientId);
    serverClient.port = _port;
    serverClient.keepAlivePeriod = 20;
    serverClient.logging(on: false);
    serverClient.setProtocolV311();
    serverClient.onConnected = _onConnected;
    serverClient.onDisconnected = _onDisconnected;
    serverClient.onSubscribed = (_) {};
    serverClient.autoReconnect = true;
    serverClient.resubscribeOnAutoReconnect = true;
    serverClient.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();
    _client = serverClient;
  }

  Future<void> _connectAndSubscribe() async {
    try {
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _client!.subscribe(_topic, MqttQos.atMostOnce);

        _client!.updates?.listen((events) {
          if (events.isEmpty) return;

          final recMess = events.first.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          _handleIncoming(payload);
        });
      } else {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            final returnCodeName =
                _client!.connectionStatus?.returnCode?.name ?? 'unknown';
            _statusMessage = 'Connect failed: $returnCodeName';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
          _statusMessage = 'Connect error: $e';
        });
      }
    }
  }

  void _handleIncoming(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        _addLog(
          alarm: 'Unknown',
          state: 'UNKNOWN',
          time: DateTime.now().toString(),
          raw: payload,
        );
        return;
      }

      _addLog(
        alarm: decoded['alarm']?.toString() ?? 'Unknown',
        state: decoded['state']?.toString() ?? 'UNKNOWN',
        time: decoded['time']?.toString() ?? DateTime.now().toString(),
        raw: payload,
      );
    } catch (_) {
      _addLog(
        alarm: 'Parse error',
        state: 'INVALID',
        time: DateTime.now().toString(),
        raw: payload,
      );
    }
  }

  void _addLog({
    required String alarm,
    required String state,
    required String time,
    required String raw,
  }) {
    if (!mounted) return;

    setState(() {
      _logs.insert(
        0,
        _AlarmLogEntry(
          alarm: alarm,
          state: state,
          time: time,
          raw: raw,
        ),
      );

      if (_logs.length > 200) {
        _logs.removeRange(200, _logs.length);
      }
    });
  }

  void _onConnected() {
    if (!mounted) return;

    setState(() {
      _isConnected = true;
      _isConnecting = false;
      _statusMessage = 'Connected';
    });
  }

  void _onDisconnected() {
    if (!mounted) return;

    setState(() {
      _isConnected = false;
      _isConnecting = false;
      final returnCodeName =
          _client?.connectionStatus?.returnCode?.name ?? 'unknown';
      _statusMessage = 'Disconnected: $returnCodeName';
    });
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }

  Color _stateColor(String state) {
    if (state.toUpperCase() == 'ON') return Colors.green;
    if (state.toUpperCase() == 'OFF') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Логи'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isConnected
                        ? 'Connected'
                        : (_isConnecting ? 'Connecting...' : 'Disconnected'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _isConnecting
                      ? 'Підключення до MQTT...'
                      : '$_statusMessage\n\nНемає даних у топіку $_topic',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(log.alarm),
                    subtitle: Text(log.time),
                    trailing: Text(
                      log.state,
                      style: TextStyle(
                        color: _stateColor(log.state),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AlarmLogEntry {
  final String alarm;
  final String state;
  final String time;
  final String raw;

  const _AlarmLogEntry({
    required this.alarm,
    required this.state,
    required this.time,
    required this.raw,
  });
}
