import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/models/sms_message.dart';
import 'package:flutterlabslpnu/pages/settings_page.dart';
import 'package:flutterlabslpnu/pages/user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  static const _channel = MethodChannel('alarm_sms');

  List<AlarmConfig> alarms = [];
  List<SmsMessage> smsList = [];
  List<String> _alarmOrder = [];

  @override
  void initState() {
    super.initState();
    requestDefaultSms();
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();

    final alarmsJson = prefs.getStringList('alarms');
    final savedOrder = prefs.getStringList('alarmOrder') ?? [];

    if (alarmsJson == null || alarmsJson.isEmpty) {
      final defaultAlarms = [
        AlarmConfig(
          title: 'Кабінет',
          phone: '+380676739457',
          arm: '721801',
          disarm: '7218*10',
        ),
        AlarmConfig(
          title: 'Гараж',
          phone: '+380676739457',
          arm: '721801',
          disarm: '721800',
        ),
        AlarmConfig(
          title: 'Село',
          phone: '+380676739457',
          arm: '721801',
          disarm: '721800',
        ),
        AlarmConfig(
          title: 'Квартира',
          phone: '+380676739457',
          arm: '721801',
          disarm: '721800',
        ),
        AlarmConfig(
          title: 'Бабуся Леся',
          phone: '+380676739457',
          arm: '721801',
          disarm: '721800',
        ),
        AlarmConfig(
          title: 'Кладовка кабінет',
          phone: '+380676739457',
          arm: '7218*29',
          disarm: '7218*20',
        ),
      ];

      final json = defaultAlarms
          .map((a) => '${a.title}|${a.phone}|${a.arm}|${a.disarm}')
          .toList();

      await prefs.setStringList('alarms', json);
    }

    final alarmsList = prefs.getStringList('alarms') ?? [];

    List<AlarmConfig> loaded = alarmsList.map((json) {
      final parts = json.split('|');

      return AlarmConfig(
        title: parts[0],
        phone: parts[1],
        arm: parts[2],
        disarm: parts[3],
      );
    }).toList();

    if (savedOrder.isNotEmpty) {
      final Map<String, AlarmConfig> map = {
        for (var alarm in loaded) alarm.title: alarm,
      };

      final List<AlarmConfig> sorted = [];

      for (String title in savedOrder) {
        if (map.containsKey(title)) {
          sorted.add(map[title]!);
          map.remove(title);
        }
      }

      sorted.addAll(map.values);
      loaded = sorted;
    }

    setState(() {
      alarms = loaded;
      _alarmOrder = alarms.map((a) => a.title).toList();
    });
  }

  Future<void> _saveAlarmOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('alarmOrder', _alarmOrder);
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
      key: ValueKey(alarm.title),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сигналізація + SMS'),
        actions: [
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
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;

            final AlarmConfig item = alarms.removeAt(oldIndex);
            alarms.insert(newIndex, item);

            _alarmOrder = alarms.map((a) => a.title).toList();
            _saveAlarmOrder();
          });
        },
        children: [
          for (int i = 0; i < alarms.length; i++) alarmBlock(alarms[i], i),
        ],
      ),
    );
  }
}
