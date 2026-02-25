import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/pages/alarm_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final _validUser = 'igor';
  final _validPass = '7218';

  bool _obscureText = true;

  void _attemptLogin() {
    if (_userController.text.trim() == _validUser &&
        _passController.text == _validPass) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<Widget>(
          builder: (_) => const AlarmPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Невірний логін або пароль')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Igor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: _inputDecoration('Логін'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passController,
              obscureText: _obscureText,
              decoration: _inputDecoration('Пароль').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _attemptLogin,
                child: const Text('Увійти'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // поки нічого не робимо
              },
              child: const Text(
                'Create Account',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}