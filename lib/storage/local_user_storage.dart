import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserStorage implements UserStorage {
  static const String _userKey = 'user';
  static const String _sessionKey = 'session_active';
  static const String _sessionExpiresAtKey = 'session_expires_at_ms';
  static const Duration _sessionDuration = Duration(minutes: 15);

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

    if (isActive) {
      final expiresAt = DateTime.now()
          .add(_sessionDuration)
          .millisecondsSinceEpoch;
      await prefs.setBool(_sessionKey, true);
      await prefs.setInt(_sessionExpiresAtKey, expiresAt);
      return;
    }

    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_sessionExpiresAtKey);
  }

  @override
  Future<bool> isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_sessionKey) ?? false;

    if (!isActive) return false;

    final expiresAt = prefs.getInt(_sessionExpiresAtKey);

    if (expiresAt == null ||
      DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      await prefs.setBool(_sessionKey, false);
      await prefs.remove(_sessionExpiresAtKey);
      return false;
    }

    return true;
  }
}
