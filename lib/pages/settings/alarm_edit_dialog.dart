import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/pages/settings/settings_input_field.dart';

Future<bool> showAlarmEditDialog({
  required BuildContext context,
  required AlarmConfig alarm,
  required Future<void> Function({
    required String title,
    required String phone,
    required String arm,
    required String disarm,
  }) onSave,
}) async {
  final nameController = TextEditingController(text: alarm.title);
  final phoneController = TextEditingController(text: alarm.phone);
  final armController = TextEditingController(text: alarm.arm);
  final disarmController = TextEditingController(text: alarm.disarm);

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Редагувати сигналізацію'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SettingsInputField(label: 'Назва', controller: nameController),
            SettingsInputField(label: 'Телефон', controller: phoneController),
            SettingsInputField(
              label: 'Код ввімкнення',
              controller: armController,
            ),
            SettingsInputField(
              label: 'Код вимкнення',
              controller: disarmController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: () async {
            await onSave(
              title: nameController.text,
              phone: phoneController.text,
              arm: armController.text,
              disarm: disarmController.text,
            );
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Зберегти'),
        ),
      ],
    ),
  );

  return saved ?? false;
}
