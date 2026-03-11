import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _armController = TextEditingController();
  final TextEditingController _disarmController = TextEditingController();

  String currentPassword = '';

  List<AlarmConfig> alarms = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _loadPassword();
    _loadAlarms();
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData == null) return;

    final user = User.fromStorage(userData);

    if (!mounted) return;

    setState(() {
      currentPassword = user.password;
    });
  }

  Future<void> _savePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    
    if (_passwordController.text.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Пароль має бути мінімум 4 символи')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData == null) return;

    final user = User.fromStorage(userData);

    final updatedUser = User(
      username: user.username,
      password: _passwordController.text,
    );

    await prefs.setString('user', updatedUser.toStorage());

    if (!mounted) return;

    setState(() {
      currentPassword = _passwordController.text;
      _passwordController.clear();
    });

    messenger.showSnackBar(
      const SnackBar(content: Text('Пароль змінено')),
    );
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];

    if (!mounted) return;

    setState(() {
      alarms = alarmsJson.map((json) {
        final parts = json.split('|');
        return AlarmConfig(
          title: parts[0],
          phone: parts[1],
          arm: parts[2],
          disarm: parts[3],
        );
      }).toList();
    });
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms
        .map((a) => '${a.title}|${a.phone}|${a.arm}|${a.disarm}')
        .toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> _addAlarm() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final arm = _armController.text.trim();
    final disarm = _disarmController.text.trim();

    if (name.isEmpty || phone.isEmpty || arm.isEmpty || disarm.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Заповніть усі поля')),
      );
      return;
    }

    final newAlarm = AlarmConfig(
      title: name,
      phone: phone,
      arm: arm,
      disarm: disarm,
    );

    setState(() {
      alarms.add(newAlarm);
    });

    await _saveAlarms();

    if (!mounted) return;

    _nameController.clear();
    _phoneController.clear();
    _armController.clear();
    _disarmController.clear();

    messenger.showSnackBar(
      const SnackBar(content: Text('Сигналізація додана')),
    );
  }

  Future<void> _deleteAlarm(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      alarms.removeAt(index);
    });

    await _saveAlarms();

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Сигналізацію видалено')),
    );
  }

  Future<void> _editAlarm(int index) async {
    final alarm = alarms[index];
    final nameController = TextEditingController(text: alarm.title);
    final phoneController = TextEditingController(text: alarm.phone);
    final armController = TextEditingController(text: alarm.arm);
    final disarmController = TextEditingController(text: alarm.disarm);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редагувати сигналізацію'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field('Назва', nameController),
              field('Телефон', phoneController),
              field('Код ввімкнення', armController),
              field('Код вимкнення', disarmController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Зберігаємо стани до await
              final messenger = ScaffoldMessenger.of(this.context);
              final navigator = Navigator.of(this.context);

              final editedAlarm = AlarmConfig(
                title: nameController.text,
                phone: phoneController.text,
                arm: armController.text,
                disarm: disarmController.text,
              );

              setState(() {
                alarms[index] = editedAlarm;
              });

              await _saveAlarms();

              // Тепер використовуємо збережені змінні замість context
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Сигналізацію змінено')),
              );
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  Widget field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget pinTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Поточний пароль: $currentPassword'),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Новий пароль',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _savePassword,
            child: const Text('Зберегти пароль'),
          ),
        ],
      ),
    );
  }

  Widget addAlarmTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          field('Назва', _nameController),
          field('Телефон', _phoneController),
          field('Код ввімкнення', _armController),
          field('Код вимкнення', _disarmController),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addAlarm,
            child: const Text('Додати сигналізацію'),
          ),
        ],
      ),
    );
  }

  Widget editTab() {
    if (alarms.isEmpty) {
      return const Center(child: Text('Немає сигналізацій'));
    }

    return ListView.builder(
      itemCount: alarms.length,
      itemBuilder: (context, i) {
        final alarm = alarms[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.security),
            title: Text(alarm.title),
            subtitle: Text('Телефон: ${alarm.phone}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editAlarm(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAlarm(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _armController.dispose();
    _disarmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Password'),
            Tab(text: 'Додати'),
            Tab(text: 'Редагування'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          pinTab(),
          addAlarmTab(),
          editTab(),
        ],
      ),
    );
  }
}
