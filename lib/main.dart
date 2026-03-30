import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/auth/auth_cubit.dart';
import 'package:flutterlabslpnu/pages/alarm_page.dart';
import 'package:flutterlabslpnu/pages/pin_page.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

void main() {
  runApp(MyApp());
}

/// =====================
/// ROOT APP
/// =====================
class MyApp extends StatelessWidget {
  MyApp({super.key});

  final LocalUserStorage _storage = LocalUserStorage();
  final NetworkService _networkService = NetworkService();
  final ApiService _apiService = ApiService();

  Future<Widget> _buildInitialPage() async {
    final isSessionActive = await _storage.isSessionActive();
    final user = await _storage.getUser();
    final hasConnection = await _networkService.hasConnection();

    if (isSessionActive && user != null) {
      return AlarmPage(showOfflineWarning: !hasConnection);
    }

    return const PinPage();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalUserStorage>.value(value: _storage),
        RepositoryProvider<NetworkService>.value(value: _networkService),
        RepositoryProvider<ApiService>.value(value: _apiService),
      ],
      child: BlocProvider<AuthCubit>(
        create: (context) => AuthCubit(
          apiService: context.read<ApiService>(),
          storage: context.read<LocalUserStorage>(),
          networkService: context.read<NetworkService>(),
        ),
        child: MaterialApp(
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
        ),
      ),
    );
  }
}
