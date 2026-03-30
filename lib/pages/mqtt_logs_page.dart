import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/mqtt_logs/mqtt_logs_cubit.dart';

class MqttLogsPage extends StatelessWidget {
  const MqttLogsPage({super.key});

  Color _stateColor(String state) {
    if (state.toUpperCase() == 'ON') return Colors.green;
    if (state.toUpperCase() == 'OFF') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MqttLogsCubit>(
      create: (context) => MqttLogsCubit()..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MQTT Логи'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: BlocBuilder<MqttLogsCubit, MqttLogsState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Icon(
                          state.isConnected
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: state.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.isConnected
                              ? 'Connected'
                              : (state.isConnecting
                                  ? 'Connecting...'
                                  : 'Disconnected'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MqttLogsCubit, MqttLogsState>(
          builder: (context, state) {
            if (state.logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    state.isConnecting
                        ? 'Підключення до MQTT...'
                        : '${state.statusMessage}\n\n'
                            'Немає даних у топіку ${MqttLogsCubit.topic}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(log.alarm),
                    subtitle: Text(log.time),
                    trailing: Text(
                      log.state,
                      style: TextStyle(
                        color: _stateColor(log.state),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
