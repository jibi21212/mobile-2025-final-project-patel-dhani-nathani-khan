import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true; // store in local prefs later
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: notifications,
            onChanged: (v) => setState(() => notifications = v),
            title: const Text('Task reminders (local)'),
            subtitle: const Text('Configure in final phase with scheduling'),
          ),
          const ListTile(
            title: Text('Sign in (placeholder)'),
            subtitle: Text('Cloud sync & collaboration (final phase)'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
