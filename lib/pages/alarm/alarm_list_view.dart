import 'package:flutter/material.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';

class AlarmListView extends StatelessWidget {
  const AlarmListView({
    required this.alarms,
    required this.onReorder,
    required this.onArm,
    required this.onDisarm,
    super.key,
  });

  final List<AlarmConfig> alarms;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(AlarmConfig alarm) onArm;
  final void Function(AlarmConfig alarm) onDisarm;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: onReorder,
      children: [
        for (int i = 0; i < alarms.length; i++)
          _AlarmCard(
            key: ValueKey(alarms[i].id),
            alarm: alarms[i],
            index: i,
            onArm: () => onArm(alarms[i]),
            onDisarm: () => onDisarm(alarms[i]),
          ),
      ],
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.index,
    required this.onArm,
    required this.onDisarm,
    super.key,
  });

  final AlarmConfig alarm;
  final int index;
  final VoidCallback onArm;
  final VoidCallback onDisarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade700.withValues(alpha: 0.3)),
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
                    child:
                        Icon(Icons.drag_handle, color: Colors.green.shade700),
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
                      onPressed: onArm,
                      child: const Text('Поставити'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      onPressed: onDisarm,
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
}
