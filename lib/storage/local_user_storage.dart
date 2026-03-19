import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserStorage implements UserStorage {
  static const String _userKey = 'user';
  static const String _sessionKey = 'session_active';

  @override
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toStorage());
  }

  @override
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);

    if (data == null) return null;

    return User.fromStorage(data);
  }

  @override
  Future<void> setSessionActive(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, isActive);
  }

  @override
  Future<bool> isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }
}
