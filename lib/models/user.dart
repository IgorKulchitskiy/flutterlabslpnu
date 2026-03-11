class User {
  final String username;
  final String password;

  User({
    required this.username,
    required this.password,
  });

  String toStorage() {
    return '$username|$password';
  }

  static User fromStorage(String data) {
    final parts = data.split('|');

    return User(
      username: parts[0],
      password: parts[1],
    );
  }
}
