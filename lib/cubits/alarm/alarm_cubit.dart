import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

class AlarmState {
  const AlarmState({
    this.alarms = const <AlarmConfig>[],
    this.isOnline = true,
    this.isLoading = false,
    this.message,
    this.messageTick = 0,
    this.sessionExpiredTick = 0,
  });

  final List<AlarmConfig> alarms;
  final bool isOnline;
  final bool isLoading;
  final String? message;
  final int messageTick;
  final int sessionExpiredTick;

  AlarmState copyWith({
    List<AlarmConfig>? alarms,
    bool? isOnline,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    int? messageTick,
    int? sessionExpiredTick,
  }) {
    return AlarmState(
      alarms: alarms ?? this.alarms,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      messageTick: messageTick ?? this.messageTick,
      sessionExpiredTick: sessionExpiredTick ?? this.sessionExpiredTick,
    );
  }
}

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit({
    required ApiService apiService,
    required NetworkService networkService,
    required UserStorage storage,
  })  : _apiService = apiService,
        _networkService = networkService,
        _storage = storage,
        super(const AlarmState());

  final ApiService _apiService;
  final NetworkService _networkService;
  final UserStorage _storage;

  StreamSubscription<bool>? _connectionSubscription;
  AppLifecycleListener? _lifecycleListener;
  bool _initialized = false;

  Future<void> initialize({required bool showOfflineWarning}) async {
    if (_initialized) return;
    _initialized = true;

    _lifecycleListener =
        AppLifecycleListener(onResume: validateSessionOrExpire);

    final hasConnection = await _networkService.hasConnection();
    emit(state.copyWith(isOnline: hasConnection));

    if (showOfflineWarning && !hasConnection) {
      _pushMessage(
        '⚠ Автовхід виконано без Інтернету. Частина функцій обмежена',
      );
    }

    _connectionSubscription =
        _networkService.onConnectionChanged().listen((isOnline) {
      final wasOnline = state.isOnline;
      emit(state.copyWith(isOnline: isOnline));

      if (wasOnline && !isOnline) {
        _pushMessage('⚠ Втрачено з’єднання з Інтернетом');
      }
      if (!wasOnline && isOnline) {
        _pushMessage('✅ З’єднання з Інтернетом відновлено');
      }
    });

    await refreshAlarms();
    await validateSessionOrExpire();
  }

  Future<void> validateSessionOrExpire() async {
    final isActive = await _storage.isSessionActive();
    if (isActive) return;

    emit(
      state.copyWith(
        sessionExpiredTick: state.sessionExpiredTick + 1,
      ),
    );
  }

  Future<void> refreshAlarms() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final loaded = await _apiService.getAlarms();
      emit(
        state.copyWith(
          alarms: loaded,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage('❌ Помилка завантаження сигналізацій: $e');
    }
  }

  Future<void> reorderAlarms(int oldIndex, int newIndex) async {
    final updated = List<AlarmConfig>.from(state.alarms);
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;

    final item = updated.removeAt(oldIndex);
    updated.insert(targetIndex, item);
    emit(state.copyWith(alarms: updated));

    try {
      await _apiService
          .reorderAlarms(updated.map((alarm) => alarm.id).toList());
    } catch (e) {
      _pushMessage('❌ Помилка оновлення порядку: $e');
      await refreshAlarms();
    }
  }

  bool canSendCommands() {
    return state.isOnline;
  }

  Future<void> logout() async {
    await _storage.setSessionActive(false);
  }

  void _pushMessage(String message) {
    emit(
      state.copyWith(
        message: message,
        messageTick: state.messageTick + 1,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    _lifecycleListener?.dispose();
    return super.close();
  }
}
