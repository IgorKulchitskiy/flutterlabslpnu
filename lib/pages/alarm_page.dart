import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/models/sms_message.dart';
import 'package:flutterlabslpnu/pages/mqtt_logs_page.dart';
import 'package:flutterlabslpnu/pages/pin_page.dart';
import 'package:flutterlabslpnu/pages/settings_page.dart';
import 'package:flutterlabslpnu/pages/user_page.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/services/network_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';

class AlarmPage extends StatefulWidget {
  final bool showOfflineWarning;

  const AlarmPage({
    super.key,
    this.showOfflineWarning = false,
  });

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> with WidgetsBindingObserver {
  static const _channel = MethodChannel('alarm_sms');
  final LocalUserStorage _storage = LocalUserStorage();
  final NetworkService _networkService = NetworkService();
  final ApiService _apiService = ApiService();

  List<AlarmConfig> alarms = [];
  List<SmsMessage> smsList = [];
  StreamSubscription<bool>? _connectionSubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestDefaultSms();
    loadAlarms();
    _startConnectionMonitoring();
    _validateSessionOrLogout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSessionOrLogout();
    }
  }

  Future<void> _validateSessionOrLogout() async {
    final isSessionActive = await _storage.isSessionActive();

    if (!mounted || isSessionActive) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const PinPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _startConnectionMonitoring() async {
    final hasConnection = await _networkService.hasConnection();

    if (!mounted) return;

    setState(() {
      _isOnline = hasConnection;
    });

    if (widget.showOfflineWarning && !hasConnection) {
      showMessage(
        '⚠ Автовхід виконано без Інтернету. Частина функцій обмежена',
      );
    }

    _connectionSubscription =
        _networkService.onConnectionChanged().listen((isOnline) {
      if (!mounted) return;

      final wasOnline = _isOnline;

      setState(() {
        _isOnline = isOnline;
      });

      if (wasOnline && !isOnline) {
        showMessage('⚠ Втрачено з’єднання з Інтернетом');
      }

      if (!wasOnline && isOnline) {
        showMessage('✅ З’єднання з Інтернетом відновлено');
      }
    });
  }

  Future<void> loadAlarms() async {
    try {
      final loaded = await _apiService.getAlarms();
      if (!mounted) return;

      setState(() {
        alarms = loaded;
      });
    } catch (e) {
      if (!mounted) return;
      showMessage('❌ Помилка завантаження сигналізацій: $e');
    }
  }

  Future<void> requestDefaultSms() async {
    await _channel.invokeMethod('requestDefaultSms');
  }

  Future<void> sendSms(String phone, String text) async {
    try {
      await _channel.invokeMethod('sendSms', {
        'number': phone,
        'message': text,
      });

      showMessage('✅ SMS відправлено');
    } catch (e) {
      showMessage('❌ Помилка SMS:\n$e');
    }
  }

  Future<void> confirmAndSend({
    required String phone,
    required String message,
    required bool isArm,
  }) async {
    if (!_isOnline) {
      showMessage('⚠ Немає Інтернету. Надсилання тимчасово недоступне');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження'),
        content: Text(
          isArm
              ? 'Ви точно хочете поставити на охорону?'
              : 'Ви точно хочете зняти з охорони?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ТАК'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('НІ'),
          ),
        ],
      ),
    );

    if (result == true) {
      sendSms(phone, message);
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget alarmBlock(AlarmConfig alarm, int index) {
    return Container(
      key: ValueKey(alarm.id),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.green.shade700.withValues(alpha: 0.3),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade800,
                Colors.grey.shade900,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      alarm.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      onPressed: () => confirmAndSend(
                        phone: alarm.phone,
                        message: alarm.arm,
                        isArm: true,
                      ),
                      child: const Text('Поставити'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      onPressed: () => confirmAndSend(
                        phone: alarm.phone,
                        message: alarm.disarm,
                        isArm: false,
                      ),
                      child: const Text('Зняти'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsPage(),
      ),
    );

    await loadAlarms();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вихід із додатку'),
        content: const Text('Ви дійсно хочете вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await _storage.setSessionActive(false);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const PinPage(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сигналізація + SMS'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                  color: _isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const UserPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MqttLogsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) async {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;

            final AlarmConfig item = alarms.removeAt(oldIndex);
            alarms.insert(newIndex, item);
          });

          try {
            await _apiService.reorderAlarms(alarms.map((a) => a.id).toList());
          } catch (e) {
            if (!mounted) return;
            showMessage('❌ Помилка оновлення порядку: $e');
            await loadAlarms();
          }
        },
        children: [
          for (int i = 0; i < alarms.length; i++) alarmBlock(alarms[i], i),
        ],
      ),
    );
  }
}
