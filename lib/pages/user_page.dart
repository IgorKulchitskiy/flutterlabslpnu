import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserStorage _storage = LocalUserStorage();
  final ApiService _authApi = ApiService();

  Future<User?> _loadUserFromApi() async {
    final savedUser = await _storage.getUser();
    if (savedUser == null) return null;

    final apiUser = await _authApi.getProfile(savedUser.username);
    return apiUser ?? savedUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: FutureBuilder<User?>(
        future: _loadUserFromApi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Помилка завантаження: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('Немає користувача'));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80),
                const SizedBox(height: 20),
                Text(
                  'Username: ${user.username}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Password: ${user.password}',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
