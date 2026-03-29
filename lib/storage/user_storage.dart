import 'package:flutterlabslpnu/models/user.dart';

abstract class UserStorage {
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> clearAuthToken();
  Future<void> setSessionActive(bool isActive);
  Future<bool> isSessionActive();
}
