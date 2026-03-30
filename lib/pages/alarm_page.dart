import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/alarm/alarm_cubit.dart';
import 'package:flutterlabslpnu/pages/alarm/alarm_page_body.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key, this.showOfflineWarning = false});

  final bool showOfflineWarning;
  static const MethodChannel _channel = MethodChannel('alarm_sms');

  Future<void> _requestDefaultSms() async {
    await _channel.invokeMethod('requestDefaultSms');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlarmCubit>(
      create: (context) {
        final cubit = AlarmCubit(
          apiService: context.read<ApiService>(),
          networkService: context.read<NetworkService>(),
          storage: context.read<LocalUserStorage>(),
        );
        _requestDefaultSms();
        cubit.initialize(showOfflineWarning: showOfflineWarning);
        return cubit;
      },
      child: const AlarmPageBody(),
    );
  }
}
