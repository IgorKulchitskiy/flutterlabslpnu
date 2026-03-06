import 'package:flutter/material.dart';

import 'package:flutterlabslpnu/pages/change_pin_page.dart';
import 'package:flutterlabslpnu/widgets/app_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Alarm text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(
                    builder: (_) => const ChangePinPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Save',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
