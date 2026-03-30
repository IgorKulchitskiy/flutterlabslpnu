import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/pages/settings/settings_input_field.dart';

class PasswordTab extends StatelessWidget {
  const PasswordTab({
    required this.currentPassword,
    required this.isLoading,
    required this.passwordController,
    required this.onSave,
    super.key,
  });

  final String currentPassword;
  final bool isLoading;
  final TextEditingController passwordController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Поточний пароль: $currentPassword'),
          const SizedBox(height: 20),
          SettingsInputField(
            label: 'Новий пароль',
            controller: passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onSave,
            child: const Text('Зберегти пароль'),
          ),
        ],
      ),
    );
  }
}

class AddAlarmTab extends StatelessWidget {
  const AddAlarmTab({
    required this.isLoading,
    required this.nameController,
    required this.phoneController,
    required this.armController,
    required this.disarmController,
    required this.onAdd,
    super.key,
  });

  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController armController;
  final TextEditingController disarmController;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SettingsInputField(
            label: 'Назва',
            controller: nameController,
          ),
          SettingsInputField(
            label: 'Телефон',
            controller: phoneController,
          ),
          SettingsInputField(
            label: 'Код ввімкнення',
            controller: armController,
          ),
          SettingsInputField(
            label: 'Код вимкнення',
            controller: disarmController,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onAdd,
            child: const Text('Додати сигналізацію'),
          ),
        ],
      ),
    );
  }
}

class EditAlarmsTab extends StatelessWidget {
  const EditAlarmsTab({
    required this.alarms,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<AlarmConfig> alarms;
  final bool isLoading;
  final void Function(int index, AlarmConfig alarm) onEdit;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: isLoading ? null : () => onEdit(i, alarm),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: isLoading ? null : () => onDelete(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
