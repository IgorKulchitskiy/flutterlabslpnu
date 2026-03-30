import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/settings/settings_cubit.dart';
import 'package:flutterlabslpnu/pages/settings/settings_view.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (context) => SettingsCubit(
        apiService: context.read<ApiService>(),
        storage: context.read<LocalUserStorage>(),
      )..initialize(),
      child: const SettingsView(),
    );
  }
}
