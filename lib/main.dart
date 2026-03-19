import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/pages/alarm_page.dart';
import 'package:flutterlabslpnu/pages/pin_page.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

void main() {
  runApp(const MyApp());
}

/// =====================
/// ROOT APP
/// =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _buildInitialPage() async {
    final storage = LocalUserStorage();
    final networkService = NetworkService();
    final isSessionActive = await storage.isSessionActive();
    final user = await storage.getUser();
    final hasConnection = await networkService.hasConnection();

    if (isSessionActive && user != null) {
      return AlarmPage(showOfflineWarning: !hasConnection);
    }

    return const PinPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: FutureBuilder<Widget>(
        future: _buildInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data ?? const PinPage();
        },
      ),
    );
  }
}
