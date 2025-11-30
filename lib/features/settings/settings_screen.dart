import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  final _notificationService = NotificationService();
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: notifications,
                  onChanged: (v) => setState(() => notifications = v),
                  title: const Text('Task Reminders'),
                  subtitle: const Text('Get notified 1 hour before task due time'),
                  secondary: Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.notification_important,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Test Notification'),
                  subtitle: const Text('Send a test notification'),
                  trailing: const Icon(Icons.send),
                  onTap: () async {
                    await _notificationService.showImmediateNotification(
                      'Test Notification',
                      'This is a test notification from Task Manager',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test notification sent!')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Test Scheduled Notification'),
                  subtitle: const Text('Schedule a notification for 10 seconds from now'),
                  trailing: const Icon(Icons.timer),
                  onTap: () async {
                    await _notificationService.testScheduledNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification scheduled for 10 seconds from now!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                  trailing: const Text('System'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.cloud_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Cloud Sync'),
                  subtitle: const Text('Coming soon'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Collaboration'),
                  subtitle: const Text('Coming soon'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('About'),
              subtitle: const Text('Task Manager v1.0.0'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}
