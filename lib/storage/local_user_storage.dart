import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserStorage implements UserStorage {
  @override
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', user.toStorage());
  }

  @override
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');

    if (data == null) return null;

    return User.fromStorage(data);
  }
}
