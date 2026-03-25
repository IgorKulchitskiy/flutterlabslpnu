import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';
import 'package:http/http.dart' as http;

class LoginResult {
  final User user;
  final String token;

  LoginResult({
    required this.user,
    required this.token,
  });
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String _baseUrl;
  final LocalUserStorage _storage = LocalUserStorage();

  Future<User> register({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/register');
    debugPrint('[API] POST $uri');

    late final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Не вдалося підключитися до API ($_baseUrl): $e');
    }

    debugPrint('[API] ${response.statusCode} POST $uri');

    if (response.statusCode == 201) {
      return _parseUser(response.body);
    }

    if (response.statusCode == 409) {
      throw Exception('Користувач з таким email вже існує');
    }

    throw Exception('Помилка реєстрації. Код: ${response.statusCode}');
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/login');
    debugPrint('[API] POST $uri');

    late final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Не вдалося підключитися до API ($_baseUrl): $e');
    }

    debugPrint('[API] ${response.statusCode} POST $uri');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Некоректна відповідь сервера');
      }

      final user = User(
        username: (decoded['username'] ?? '').toString(),
        password: (decoded['password'] ?? '').toString(),
      );
      final token = (decoded['token'] ?? '').toString();

      if (token.isEmpty) {
        throw Exception('Сервер не повернув токен доступу');
      }

      return LoginResult(user: user, token: token);
    }

    if (response.statusCode == 401) {
      throw Exception('Невірний логін або пароль');
    }

    throw Exception('Помилка логіну. Код: ${response.statusCode}');
  }

  Future<User?> getProfile(String username) async {
    final response = await _withAuthRetry((headers) {
      return _client.get(
        Uri.parse('$_baseUrl/api/users/$username'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw Exception(
      'Помилка завантаження профілю. Код: ${response.statusCode}',
    );
  }

  Future<User> updatePassword({
    required String username,
    required String newPassword,
  }) async {
    final response = await _withAuthRetry((headers) {
      return _client.patch(
        Uri.parse('$_baseUrl/api/users/$username/password'),
        headers: headers,
        body: jsonEncode({'newPassword': newPassword}),
      );
    });

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    if (response.statusCode == 404) {
      throw Exception('Користувача не знайдено');
    }

    throw Exception('Помилка зміни пароля. Код: ${response.statusCode}');
  }

  Future<List<AlarmConfig>> getAlarms() async {
    final response = await _withAuthRetry((headers) {
      return _client.get(
        Uri.parse('$_baseUrl/api/alarms'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception(
        'Помилка завантаження сигналізацій. Код: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Некоректна відповідь сервера');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AlarmConfig.fromJson)
        .toList();
  }

  Future<AlarmConfig> createAlarm({
    required String title,
    required String phone,
    required String arm,
    required String disarm,
  }) async {
    final response = await _withAuthRetry((headers) {
      return _client.post(
        Uri.parse('$_baseUrl/api/alarms'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'phone': phone,
          'arm': arm,
          'disarm': disarm,
        }),
      );
    });

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Некоректна відповідь сервера');
      }

      return AlarmConfig.fromJson(decoded);
    }

    throw Exception(
      'Помилка додавання сигналізації. Код: ${response.statusCode}',
    );
  }

  Future<AlarmConfig> updateAlarm({
    required int id,
    required String title,
    required String phone,
    required String arm,
    required String disarm,
  }) async {
    final response = await _withAuthRetry((headers) {
      return _client.patch(
        Uri.parse('$_baseUrl/api/alarms/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'phone': phone,
          'arm': arm,
          'disarm': disarm,
        }),
      );
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Некоректна відповідь сервера');
      }

      return AlarmConfig.fromJson(decoded);
    }

    throw Exception(
      'Помилка редагування сигналізації. Код: ${response.statusCode}',
    );
  }

  Future<void> deleteAlarm(int id) async {
    final response = await _withAuthRetry((headers) {
      return _client.delete(
        Uri.parse('$_baseUrl/api/alarms/$id'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception(
        'Помилка видалення сигналізації. Код: ${response.statusCode}',
      );
    }
  }

  Future<void> reorderAlarms(List<int> orderedIds) async {
    final response = await _withAuthRetry((headers) {
      return _client.patch(
        Uri.parse('$_baseUrl/api/alarms/reorder'),
        headers: headers,
        body: jsonEncode({'ids': orderedIds}),
      );
    });

    if (response.statusCode != 200) {
      throw Exception(
        'Помилка зміни порядку сигналізацій. Код: ${response.statusCode}',
      );
    }
  }

  User _parseUser(String jsonPayload) {
    final decoded = jsonDecode(jsonPayload);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Некоректна відповідь сервера');
    }

    return User(
      username: (decoded['username'] ?? '').toString(),
      password: (decoded['password'] ?? '').toString(),
    );
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _getOrRefreshToken();
    return {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    };
  }

  Future<String> _getOrRefreshToken() async {
    final token = await _storage.getAuthToken();

    if (token == null || token.isEmpty) {
      return _refreshTokenFromStoredUser();
    }

    return token;
  }

  Future<String> _refreshTokenFromStoredUser() async {
    final user = await _storage.getUser();
    if (user == null) {
      throw Exception('Відсутній токен авторизації');
    }

    final result = await login(
      username: user.username,
      password: user.password,
    );
    await _storage.saveUser(result.user);
    await _storage.saveAuthToken(result.token);

    return result.token;
  }

  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final initialHeaders = await _authorizedHeaders();
    final initialResponse = await request(initialHeaders);

    if (initialResponse.statusCode != 401) {
      return initialResponse;
    }

    final refreshed = await _refreshTokenFromStoredUser();
    final retriedHeaders = {
      'content-type': 'application/json',
      'authorization': 'Bearer $refreshed',
    };

    final retriedResponse = await request(retriedHeaders);
    return retriedResponse;
  }

  static String _resolveBaseUrl() {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) return 'http://127.0.0.1:8080';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://127.0.0.1:8080';
  }
}
