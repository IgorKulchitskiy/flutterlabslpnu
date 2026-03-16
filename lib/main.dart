import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/pages/pin_page.dart';

void main() {
  runApp(const MyApp());
}

/// =====================
/// ROOT APP
/// =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const PinPage(),
    );
  }
}
