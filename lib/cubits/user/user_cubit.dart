import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

class UserState {
  const UserState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  final bool isLoading;
  final User? user;
  final String? error;

  UserState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool clearError = false,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserCubit extends Cubit<UserState> {
  UserCubit({required ApiService apiService, required UserStorage storage})
      : _apiService = apiService,
        _storage = storage,
        super(const UserState());

  final ApiService _apiService;
  final UserStorage _storage;

  Future<void> loadUser() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final savedUser = await _storage.getUser();
      if (savedUser == null) {
        emit(const UserState());
        return;
      }

      final apiUser = await _apiService.getProfile(savedUser.username);
      emit(UserState(user: apiUser ?? savedUser));
    } catch (e) {
      emit(UserState(error: 'Помилка завантаження: $e'));
    }
  }
}
