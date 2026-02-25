import 'package:flutter/material.dart';

import 'package:flutterlabslpnu/pages/edit_alarm_page.dart';

class AppCard extends StatelessWidget {
  final String title;

  const AppCard({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.home),
        title: Text(title),
        trailing: SizedBox(
          width: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.lock_outline),
                tooltip: 'Arm',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.lock_open),
                tooltip: 'Disarm',
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<Widget>(
                      builder: (_) => const EditAlarmPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
