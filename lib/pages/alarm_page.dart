import 'package:flutter/material.dart';

import 'package:flutterlabslpnu/pages/add_alarm_page.dart';
import 'package:flutterlabslpnu/pages/profile_page.dart';
import 'package:flutterlabslpnu/pages/settings_page.dart';
import 'package:flutterlabslpnu/widgets/app_card.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  bool _navigatedBySwipe = false;

  void _handleSwipeRight() {
    if (_navigatedBySwipe) return;

    _navigatedBySwipe = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute<Widget>(
            builder: (_) => const SettingsPage(),
          ),
        )
        .then((_) {
      _navigatedBySwipe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<Widget>(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<Widget>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx > 12) {
            _handleSwipeRight();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            AppCard(title: 'Home Alarm'),
            AppCard(title: 'Garage Alarm'),
            AppCard(title: 'Office Alarm'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<Widget>(
              builder: (_) => const AddAlarmPage(),
            ),
          );
        },
        tooltip: 'Add Alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}
