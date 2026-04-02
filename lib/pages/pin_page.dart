import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/auth/auth_cubit.dart';
import 'package:flutterlabslpnu/pages/alarm_page.dart';
import 'package:flutterlabslpnu/pages/register_page.dart';
import 'package:secret_torch_plugin/secret_torch_plugin.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _secretTapCount = 0;
  DateTime? _lastSecretTapAt;
  DateTime? _lastShakeAt;
  bool _torchEnabled = false;

  static const double _shakeThreshold = 2.7;
  static const Duration _shakeCooldown = Duration(seconds: 2);

  Future<void> checkLogin() async {
    final String login = loginController.text.trim();
    final String password = passwordController.text.trim();
    await context.read<AuthCubit>().login(username: login, password: password);
  }

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
    );
  }

  Future<void> _toggleHiddenTorch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Функція не підтримується'),
          content: const Text(
            'Секретне керування ліхтариком доступне лише на Android.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final isEnabled = await SecretTorchPlugin.onLight();
      _torchEnabled = isEnabled;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled ? 'Ліхтарик увімкнено' : 'Ліхтарик вимкнено',
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Не вдалося перемкнути ліхтарик',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Помилка перемикання ліхтарика'),
        ),
      );
    }
  }

  Future<void> _toggleHiddenTorchByShake() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final isEnabled = await SecretTorchPlugin.setLight(!_torchEnabled);
      _torchEnabled = isEnabled;
    } on PlatformException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не вдалося увімкнути ліхтарик'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Помилка увімкнення ліхтарика'),
        ),
      );
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    final lastShakeAt = _lastShakeAt;

    if (lastShakeAt != null && now.difference(lastShakeAt) < _shakeCooldown) {
      return;
    }

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final gForce = magnitude / 9.81;

    if (gForce < _shakeThreshold) return;

    _lastShakeAt = now;
    _toggleHiddenTorchByShake();
  }

  Future<void> _onSecretTriggerTap() async {
    final now = DateTime.now();
    final lastTapAt = _lastSecretTapAt;

    if (lastTapAt == null || now.difference(lastTapAt).inSeconds > 2) {
      _secretTapCount = 0;
    }

    _lastSecretTapAt = now;
    _secretTapCount += 1;

    if (_secretTapCount < 3) return;

    _secretTapCount = 0;
    await _toggleHiddenTorch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.action != AuthAction.login) return;

        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }

        if (state.status == AuthStatus.success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const AlarmPage(),
            ),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _onSecretTriggerTap,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.flash_on,
                        size: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'x3 tap or shake',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(50),
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
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status == AuthStatus.loading
                            ? null
                            : checkLogin,
                        child: state.status == AuthStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      );
                    },
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
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
