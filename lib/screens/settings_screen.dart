import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:harvestflow/providers/settings_provider.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SMS Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sms, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'SMS Configuration',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   initialValue: settings.arkEselApiKey,
                  //   decoration: const InputDecoration(
                  //     labelText: 'ArkESel API Key',
                  //     hintText: 'Enter your ArkESel API key',
                  //     prefixIcon: Icon(Icons.key),
                  //   ),
                  //   obscureText: true,
                  //   onChanged: (value) {
                  //     ref.read(appSettingsProvider.notifier).updateApiKey(value);
                  //   },
                  // ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: settings.smsSender,
                    decoration: const InputDecoration(
                      labelText: 'SMS Sender ID',
                      hintText: 'e.g., SoulReach',
                      prefixIcon: Icon(Icons.person),
                    ),
                    maxLength: 11,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).updateSender(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your API key from ArkESel dashboard',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto-send SMS for meetings'),
                    subtitle: const Text('Automatically send SMS when meetings are scheduled'),
                    value: settings.autoSMSEnabled,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).toggleAutoSMS(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive reminders for meetings and follow-ups'),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).toggleNotifications(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _scheduleTestNotification(context),
                    child: const Text('Send Test Notification'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _scheduleDailyEncouragement(context),
                    child: const Text('Enable Daily Encouragement'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Data Management',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Members to CSV'),
                    subtitle: const Text('Download all members as CSV file'),
                    onTap: () => _exportMembers(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Database Info'),
                    subtitle: const Text('View storage information'),
                    onTap: () => _showDatabaseInfo(context, ref),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'About SoulWinning',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Version: 1.0.0'),
                  const SizedBox(height: 8),
                  const Text('An offline-first evangelism and soul-winning app designed to streamline member management, meeting scheduling, and follow-up automation.'),
                  const SizedBox(height: 16),
                  const Text('Features:'),
                  const SizedBox(height: 8),
                  const Text('• Offline member management'),
                  const Text('• SMS integration via ArkESel'),
                  const Text('• Meeting scheduling & reminders'),
                  const Text('• Follow-up automation'),
                  const Text('• Contact integration'),
                  const Text('• CSV data export'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _scheduleTestNotification(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.showEncouragementNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent!')),
    );
  }

  void _scheduleDailyEncouragement(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.scheduleDailyEncouragement();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily encouragement scheduled for 9 AM!')),
    );
  }

  void _exportMembers(BuildContext context, WidgetRef ref) async {
    try {
      final members = await ref.read(memberListProvider.future);
      
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No members to export')),
        );
        return;
      }

      // Create CSV data
      List<List<String>> csvData = [
        ['Name', 'Phone', 'Address', 'Group', 'Notes', 'Created Date', 'Last Contact']
      ];
      
      for (var member in members) {
        csvData.add([
          member.name,
          member.phone,
          member.address,
          member.groupTag,
          member.notes,
          member.createdAt.toString(),
          member.lastContact?.toString() ?? '',
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);
      
      // In a real app, you would save this to a file
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV generated with ${members.length} members'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSV Preview'),
                  content: SingleChildScrollView(
                    child: Text(
                      csvString.length > 500 
                          ? '${csvString.substring(0, 500)}...'
                          : csvString,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _showDatabaseInfo(BuildContext context, WidgetRef ref) async {
    final stats = await ref.read(dashboardStatsProvider.future);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Total Members', value: '${stats['totalMembers'] ?? 0}'),
            _InfoRow(label: 'Upcoming Meetings', value: '${stats['upcomingMeetings'] ?? 0}'),
            _InfoRow(label: 'Pending Follow-ups', value: '${stats['pendingFollowUps'] ?? 0}'),
            _InfoRow(label: 'Overdue Follow-ups', value: '${stats['overdueFollowUps'] ?? 0}'),
            const SizedBox(height: 16),
            const Text('Storage: Local SQLite Database'),
            const Text('Location: Device internal storage'),
            const Text('Backup: Manual CSV export only'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}