import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:harvestflow/providers/settings_provider.dart';
// import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/providers/meeting_provider.dart';
import 'package:harvestflow/providers/followup_provider.dart';
import 'package:harvestflow/screens/members_screen.dart';
import 'package:harvestflow/screens/meetings_screen.dart';
import 'package:harvestflow/screens/followups_screen.dart';
import 'package:harvestflow/screens/sms_screen.dart';
import 'package:harvestflow/screens/settings_screen.dart';
import 'package:harvestflow/widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final todaysMeetingsAsync = ref.watch(todaysMeetingsProvider);
    // final overdueCountAsync = ref.watch(overdueCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SoulWinning Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(todaysMeetingsProvider);
          ref.invalidate(overdueCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.volunteer_activism, size: 32, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to SoulWinning',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to make a difference today?',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats Overview
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    StatsCard(
                      title: 'Total Members',
                      value: stats['totalMembers']?.toString() ?? '0',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MembersScreen()),
                      ),
                    ),
                    StatsCard(
                      title: 'Upcoming Meetings',
                      value: stats['upcomingMeetings']?.toString() ?? '0',
                      icon: Icons.event,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MeetingsScreen()),
                      ),
                    ),
                    StatsCard(
                      title: 'Overdue Follow-ups',
                      value: stats['overdueFollowUps']?.toString() ?? '0',
                      icon: Icons.warning,
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FollowUpsScreen()),
                      ),
                    ),
                    StatsCard(
                      title: 'Pending Follow-ups',
                      value: stats['pendingFollowUps']?.toString() ?? '0',
                      icon: Icons.schedule,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FollowUpsScreen()),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
              
              const SizedBox(height: 24),
              
              // Today's Meetings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Meetings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MeetingsScreen()),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              todaysMeetingsAsync.when(
                data: (meetings) => meetings.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.event_available, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No meetings scheduled for today',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the button below to schedule a new meeting',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: meetings.map((meeting) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.event, color: Colors.green),
                            title: Text(meeting.title),
                            subtitle: Text(DateFormat('HH:mm').format(meeting.dateTime)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MeetingsScreen()),
                            ),
                          ),
                        )).toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2,
                children: [
                  _QuickActionCard(
                    title: 'Add Member',
                    icon: Icons.person_add,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MembersScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Schedule Meeting',
                    icon: Icons.event_note,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MeetingsScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Send SMS',
                    icon: Icons.message,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SMSScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Follow-ups',
                    icon: Icons.checklist,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FollowUpsScreen()),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}