import 'package:flutterlabslpnu/models/user.dart';

abstract class UserStorage {
  Future<void> saveUser(User user);
  Future<User?> getUser();
}
