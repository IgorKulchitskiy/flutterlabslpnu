import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/alarm/alarm_cubit.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/pages/alarm/alarm_list_view.dart';
import 'package:flutterlabslpnu/pages/mqtt_logs_page.dart';
import 'package:flutterlabslpnu/pages/pin_page.dart';
import 'package:flutterlabslpnu/pages/settings_page.dart';
import 'package:flutterlabslpnu/pages/user_page.dart';

class AlarmPageBody extends StatelessWidget {
  const AlarmPageBody({super.key});

  static const MethodChannel _channel = MethodChannel('alarm_sms');

  Future<void> _sendSms(BuildContext context, String phone, String text) async {
    try {
      await _channel
          .invokeMethod('sendSms', {'number': phone, 'message': text});
      if (!context.mounted) return;
      _showMessage(context, '✅ SMS відправлено');
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(context, '❌ Помилка SMS:\n$e');
    }
  }

  Future<void> _confirmAndSend({
    required BuildContext context,
    required String phone,
    required String message,
    required bool isArm,
  }) async {
    if (!context.read<AlarmCubit>().canSendCommands()) {
      _showMessage(
        context,
        '⚠ Немає Інтернету. Надсилання тимчасово недоступне',
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Підтвердження'),
        content: Text(
          isArm
              ? 'Ви точно хочете поставити на охорону?'
              : 'Ви точно хочете зняти з охорони?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ТАК'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('НІ'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      await _sendSms(context, phone, message);
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );

    if (!context.mounted) return;
    await context.read<AlarmCubit>().refreshAlarms();
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Вихід із додатку'),
        content: const Text('Ви дійсно хочете вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    if (!context.mounted) return;

    await context.read<AlarmCubit>().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const PinPage()),
      (route) => false,
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlarmCubit, AlarmState>(
      listenWhen: (previous, current) =>
          previous.messageTick != current.messageTick ||
          previous.sessionExpiredTick != current.sessionExpiredTick,
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          _showMessage(context, state.message!);
        }

        if (state.sessionExpiredTick > 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const PinPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Сигналізація + SMS'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BlocBuilder<AlarmCubit, AlarmState>(
                buildWhen: (previous, current) =>
                    previous.isOnline != current.isOnline,
                builder: (context, state) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 18,
                        color: state.isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isOnline ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const UserPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.wifi_tethering),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const MqttLogsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _openSettings(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: BlocBuilder<AlarmCubit, AlarmState>(
          builder: (context, state) {
            return AlarmListView(
              alarms: state.alarms,
              onReorder: (oldIndex, newIndex) {
                context.read<AlarmCubit>().reorderAlarms(oldIndex, newIndex);
              },
              onArm: (AlarmConfig alarm) => _confirmAndSend(
                context: context,
                phone: alarm.phone,
                message: alarm.arm,
                isArm: true,
              ),
              onDisarm: (AlarmConfig alarm) => _confirmAndSend(
                context: context,
                phone: alarm.phone,
                message: alarm.disarm,
                isArm: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
