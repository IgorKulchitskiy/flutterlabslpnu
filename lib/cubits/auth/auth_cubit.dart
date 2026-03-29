import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

enum AuthStatus { initial, loading, success, failure }

enum AuthAction { none, login, register }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.action = AuthAction.none,
    this.message,
  });

  final AuthStatus status;
  final AuthAction action;
  final String? message;

  AuthState copyWith({
    AuthStatus? status,
    AuthAction? action,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      action: action ?? this.action,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required ApiService apiService,
    required UserStorage storage,
    required NetworkService networkService,
  })  : _apiService = apiService,
        _storage = storage,
        _networkService = networkService,
        super(const AuthState());

  final ApiService _apiService;
  final UserStorage _storage;
  final NetworkService _networkService;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final hasConnection = await _networkService.hasConnection();
    if (!hasConnection) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.login,
          message: '⚠ Немає з\'єднання з Інтернетом',
        ),
      );
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.login,
          message: '❌ Заповніть всі поля',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        action: AuthAction.login,
        clearMessage: true,
      ),
    );

    try {
      final result =
          await _apiService.login(username: username, password: password);
      await _storage.saveUser(result.user);
      await _storage.saveAuthToken(result.token);
      await _storage.setSessionActive(true);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          action: AuthAction.login,
          message: '✅ Вхід успішний',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.login,
          message: '❌ ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.register,
          message: '❌ Заповніть всі поля',
        ),
      );
      return;
    }

    if (!username.contains('@')) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.register,
          message: '❌ Email повинен містити @',
        ),
      );
      return;
    }

    if (password.length < 4) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.register,
          message: '❌ Пароль має бути мінімум 4 символи',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        action: AuthAction.register,
        clearMessage: true,
      ),
    );

    try {
      await _apiService.register(username: username, password: password);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          action: AuthAction.register,
          message: '✅ Реєстрація успішна',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          action: AuthAction.register,
          message: '❌ ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  void reset() {
    emit(const AuthState());
  }
}
