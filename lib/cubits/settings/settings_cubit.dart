import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

class SettingsState {
  const SettingsState({
    this.currentPassword = '',
    this.alarms = const <AlarmConfig>[],
    this.isLoading = false,
    this.message,
    this.messageTick = 0,
  });

  final String currentPassword;
  final List<AlarmConfig> alarms;
  final bool isLoading;
  final String? message;
  final int messageTick;

  SettingsState copyWith({
    String? currentPassword,
    List<AlarmConfig>? alarms,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    int? messageTick,
  }) {
    return SettingsState(
      currentPassword: currentPassword ?? this.currentPassword,
      alarms: alarms ?? this.alarms,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      messageTick: messageTick ?? this.messageTick,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required ApiService apiService, required UserStorage storage})
      : _apiService = apiService,
        _storage = storage,
        super(const SettingsState());

  final ApiService _apiService;
  final UserStorage _storage;

  Future<void> initialize() async {
    await _loadPassword();
    await loadAlarms();
  }

  Future<void> _loadPassword() async {
    final user = await _storage.getUser();
    if (user == null) return;

    try {
      final profile = await _apiService.getProfile(user.username);
      final userToShow = profile ?? user;
      emit(state.copyWith(currentPassword: userToShow.password));
    } catch (_) {
      emit(state.copyWith(currentPassword: user.password));
    }
  }

  Future<void> savePassword(String newPassword) async {
    if (newPassword.length < 4) {
      _pushMessage('Пароль має бути мінімум 4 символи');
      return;
    }

    final user = await _storage.getUser();
    if (user == null) {
      _pushMessage('Немає активного користувача');
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final updatedUser = await _apiService.updatePassword(
        username: user.username,
        newPassword: newPassword,
      );
      await _storage.saveUser(updatedUser);

      emit(
        state.copyWith(
          isLoading: false,
          currentPassword: updatedUser.password,
        ),
      );
      _pushMessage('Пароль змінено');
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage(
        'Помилка API: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<void> loadAlarms() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final loaded = await _apiService.getAlarms();
      emit(
        state.copyWith(
          isLoading: false,
          alarms: loaded,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage('Помилка завантаження сигналізацій: $e');
    }
  }

  Future<void> addAlarm({
    required String title,
    required String phone,
    required String arm,
    required String disarm,
  }) async {
    if (title.isEmpty || phone.isEmpty || arm.isEmpty || disarm.isEmpty) {
      _pushMessage('Заповніть усі поля');
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final createdAlarm = await _apiService.createAlarm(
        title: title,
        phone: phone,
        arm: arm,
        disarm: disarm,
      );

      final updatedAlarms = List<AlarmConfig>.from(state.alarms)
        ..add(createdAlarm);

      emit(
        state.copyWith(
          isLoading: false,
          alarms: updatedAlarms,
        ),
      );
      _pushMessage('Сигналізація додана');
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage('Помилка додавання сигналізації: $e');
    }
  }

  Future<void> deleteAlarm(int index) async {
    final alarms = state.alarms;
    if (index < 0 || index >= alarms.length) return;

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      await _apiService.deleteAlarm(alarms[index].id);
      final updatedAlarms = List<AlarmConfig>.from(alarms)..removeAt(index);
      emit(
        state.copyWith(
          isLoading: false,
          alarms: updatedAlarms,
        ),
      );
      _pushMessage('Сигналізацію видалено');
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage('Помилка видалення сигналізації: $e');
    }
  }

  Future<void> updateAlarm({
    required int index,
    required String title,
    required String phone,
    required String arm,
    required String disarm,
  }) async {
    final alarms = state.alarms;
    if (index < 0 || index >= alarms.length) return;

    emit(state.copyWith(isLoading: true, clearMessage: true));

    final alarm = alarms[index];

    try {
      final updated = await _apiService.updateAlarm(
        id: alarm.id,
        title: title,
        phone: phone,
        arm: arm,
        disarm: disarm,
      );

      final updatedAlarms = List<AlarmConfig>.from(alarms);
      updatedAlarms[index] = updated;

      emit(
        state.copyWith(
          isLoading: false,
          alarms: updatedAlarms,
        ),
      );
      _pushMessage('Сигналізацію змінено');
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _pushMessage('Помилка редагування сигналізації: $e');
    }
  }

  void _pushMessage(String message) {
    emit(
      state.copyWith(
        message: message,
        messageTick: state.messageTick + 1,
      ),
    );
  }
}
