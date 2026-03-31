import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secret_torch_plugin/secret_torch_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Press button to toggle torch';

  Future<void> _toggleTorch() async {
    try {
      final isEnabled = await SecretTorchPlugin.onLight();
      if (!mounted) return;
      setState(() {
        _status = isEnabled ? 'Torch is ON' : 'Torch is OFF';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error.message ?? 'Torch toggle failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Secret Torch Plugin Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleTorch,
                child: const Text('Toggle torch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
