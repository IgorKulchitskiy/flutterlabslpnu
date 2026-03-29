import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterlabslpnu/cubits/settings/settings_cubit.dart';
import 'package:flutterlabslpnu/models/alarm_config.dart';
import 'package:flutterlabslpnu/pages/settings/alarm_edit_dialog.dart';
import 'package:flutterlabslpnu/pages/settings/settings_tabs.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _armController = TextEditingController();
  final _disarmController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      context.read<SettingsCubit>().loadAlarms();
    }
  }

  Future<void> _savePassword() async {
    await context.read<SettingsCubit>().savePassword(_passwordController.text);
  }

  Future<void> _addAlarm() async {
    await context.read<SettingsCubit>().addAlarm(
          title: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          arm: _armController.text.trim(),
          disarm: _disarmController.text.trim(),
        );
  }

  Future<void> _editAlarmDialog(int index, AlarmConfig alarm) async {
    await showAlarmEditDialog(
      context: context,
      alarm: alarm,
      onSave: ({
        required title,
        required phone,
        required arm,
        required disarm,
      }) async {
        await context.read<SettingsCubit>().updateAlarm(
              index: index,
              title: title,
              phone: phone,
              arm: arm,
              disarm: disarm,
            );
      },
    );
  }

  void _handleStateMessage(SettingsState state) {
    final message = state.message;
    if (message == null || message.isEmpty) return;

    if (message == 'Пароль змінено') _passwordController.clear();

    if (message == 'Сигналізація додана') {
      _nameController.clear();
      _phoneController.clear();
      _armController.clear();
      _disarmController.clear();
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.messageTick != current.messageTick,
      listener: (context, state) => _handleStateMessage(state),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
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
                PasswordTab(
                  currentPassword: state.currentPassword,
                  isLoading: state.isLoading,
                  passwordController: _passwordController,
                  onSave: _savePassword,
                ),
                AddAlarmTab(
                  isLoading: state.isLoading,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  armController: _armController,
                  disarmController: _disarmController,
                  onAdd: _addAlarm,
                ),
                EditAlarmsTab(
                  alarms: state.alarms,
                  isLoading: state.isLoading,
                  onEdit: _editAlarmDialog,
                  onDelete: (index) {
                    context.read<SettingsCubit>().deleteAlarm(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
