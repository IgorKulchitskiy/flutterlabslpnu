import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/models/user.dart';
import 'package:flutterlabslpnu/services/api_service.dart';
import 'package:flutterlabslpnu/storage/local_user_storage.dart';
import 'package:flutterlabslpnu/storage/user_storage.dart';

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
  final UserStorage _storage = LocalUserStorage();
  final ApiService _authApi = ApiService();

  List<AlarmConfig> alarms = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);

    _loadPassword();
    _loadAlarms();
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      _loadAlarms();
    }
  }

  Future<void> _loadPassword() async {
    final user = await _storage.getUser();
    if (user == null) return;

    final profile = await _authApi.getProfile(user.username);
    final userToShow = profile ?? user;

    if (!mounted) return;

    setState(() {
      currentPassword = userToShow.password;
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

    final user = await _storage.getUser();
    if (user == null) return;

    late final User updatedUser;
    try {
      updatedUser = await _authApi.updatePassword(
        username: user.username,
        newPassword: _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Помилка API: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
      return;
    }

    await _storage.saveUser(updatedUser);

    if (!mounted) return;

    setState(() {
      currentPassword = updatedUser.password;
      _passwordController.clear();
    });

    messenger.showSnackBar(
      const SnackBar(content: Text('Пароль змінено')),
    );
  }

  Future<void> _loadAlarms() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final loaded = await _authApi.getAlarms();

      if (!mounted) return;

      setState(() {
        alarms = loaded;
      });
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Помилка завантаження сигналізацій: $e')),
      );
    }
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

    try {
      final createdAlarm = await _authApi.createAlarm(
        title: name,
        phone: phone,
        arm: arm,
        disarm: disarm,
      );

      setState(() {
        alarms.add(createdAlarm);
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка додавання сигналізації: $e')),
      );
      return;
    }

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
    final alarmId = alarms[index].id;

    try {
      await _authApi.deleteAlarm(alarmId);

      setState(() {
        alarms.removeAt(index);
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка видалення сигналізації: $e')),
      );
      return;
    }

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
                id: alarm.id,
                title: nameController.text,
                phone: phoneController.text,
                arm: armController.text,
                disarm: disarmController.text,
              );

              try {
                final updated = await _authApi.updateAlarm(
                  id: editedAlarm.id,
                  title: editedAlarm.title,
                  phone: editedAlarm.phone,
                  arm: editedAlarm.arm,
                  disarm: editedAlarm.disarm,
                );

                if (!mounted) return;

                setState(() {
                  alarms[index] = updated;
                });
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Помилка редагування сигналізації: $e'),
                  ),
                );
                return;
              }

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
    _tabController.removeListener(_handleTabChanged);
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
