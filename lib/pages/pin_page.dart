import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/pages/alarm_page.dart';
import 'package:flutterlabslpnu/pages/register_page.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final storage = LocalUserStorage();
  final networkService = NetworkService();

  Future<void> checkLogin() async {
    final hasConnection = await networkService.hasConnection();

    if (!mounted) return;

    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Немає з’єднання з Інтернетом')),
      );
      return;
    }

    final User? user = await storage.getUser();

    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Користувач не зареєстрований')),
      );
      return;
    }

    final String login = loginController.text.trim();
    final String password = passwordController.text.trim();

    if (login == user.username && password == user.password) {
      await storage.setSessionActive(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const AlarmPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Невірний логін або пароль')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: loginController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: checkLogin,
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
