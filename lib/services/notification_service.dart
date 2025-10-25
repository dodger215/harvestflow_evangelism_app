import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:harvestflow/models/meeting.dart';
import 'package:harvestflow/models/followup.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleMeetingReminder(Meeting meeting) async {
    await initialize();
    
    // Schedule notification 30 minutes before meeting
    final reminderTime = meeting.dateTime.subtract(const Duration(minutes: 30));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await _notifications.show(
        meeting.id ?? 0,
        'Meeting Reminder',
        '${meeting.title} starts in 30 minutes',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meeting_reminders',
            'Meeting Reminders',
            channelDescription: 'Notifications for upcoming meetings',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  Future<void> scheduleFollowUpReminder(FollowUp followUp, String memberName) async {
    await initialize();
    
    if (followUp.dueDate.isAfter(DateTime.now()) && !followUp.isCompleted) {
      await _notifications.show(
        (followUp.id ?? 0) + 1000, // Offset to avoid conflicts with meeting IDs
        'Follow-Up Reminder',
        'Follow-up due for $memberName: ${followUp.type}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'followup_reminders',
            'Follow-Up Reminders',
            channelDescription: 'Notifications for follow-up activities',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  Future<void> showEncouragementNotification() async {
    await initialize();
    
    const encouragementMessages = [
      'Send a check-in text to someone today!',
      'Remember to pray for your members',
      'Your ministry makes a difference!',
      'Time to reach out and encourage someone',
      'Every soul matters - keep going!',
    ];
    
    final randomMessage = encouragementMessages[DateTime.now().millisecond % encouragementMessages.length];
    
    await _notifications.show(
      9999,
      'SoulWinning Encouragement',
      randomMessage,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'encouragement',
          'Encouragement',
          channelDescription: 'Daily encouragement for ministry',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleDailyEncouragement() async {
    await initialize();
    
    // Schedule daily encouragement at 9 AM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.show(
      8888,
      'Daily Encouragement',
      'Start your day with purpose - souls are waiting!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_encouragement',
          'Daily Encouragement',
          channelDescription: 'Daily motivation for ministry',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelMeetingNotification(int meetingId) async {
    await _notifications.cancel(meetingId);
  }

  Future<void> cancelFollowUpNotification(int followUpId) async {
    await _notifications.cancel(followUpId + 1000);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}