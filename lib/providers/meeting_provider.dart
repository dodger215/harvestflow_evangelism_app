import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/models/meeting.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/services/database_service.dart';
import 'package:harvestflow/services/notification_service.dart';

final upcomingMeetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getUpcomingMeetings();
});

class MeetingNotifier extends StateNotifier<AsyncValue<List<Meeting>>> {
  MeetingNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadMeetings();
  }

  final DatabaseService _databaseService;
  final NotificationService _notificationService = NotificationService();

  Future<void> loadMeetings() async {
    try {
      state = const AsyncValue.loading();
      final meetings = await _databaseService.getMeetings();
      state = AsyncValue.data(meetings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMeeting(Meeting meeting, {bool scheduleNotification = true}) async {
    try {
      final id = await _databaseService.insertMeeting(meeting);
      
      if (scheduleNotification) {
        final meetingWithId = meeting.copyWith(id: id);
        await _notificationService.scheduleMeetingReminder(meetingWithId);
      }
      
      await loadMeetings();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMeeting(Meeting meeting, {bool rescheduleNotification = true}) async {
    try {
      await _databaseService.updateMeeting(meeting);
      
      if (rescheduleNotification && meeting.id != null) {
        await _notificationService.cancelMeetingNotification(meeting.id!);
        if (!meeting.isCompleted) {
          await _notificationService.scheduleMeetingReminder(meeting);
        }
      }
      
      await loadMeetings();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMeeting(int id) async {
    try {
      await _databaseService.deleteMeeting(id);
      await _notificationService.cancelMeetingNotification(id);
      await loadMeetings();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeMeeting(int id) async {
    try {
      final meetings = await _databaseService.getMeetings();
      final meeting = meetings.firstWhere((m) => m.id == id);
      final completedMeeting = meeting.copyWith(isCompleted: true);
      await updateMeeting(completedMeeting, rescheduleNotification: true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final meetingNotifierProvider = StateNotifierProvider<MeetingNotifier, AsyncValue<List<Meeting>>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return MeetingNotifier(databaseService);
});

final todaysMeetingsProvider = Provider<AsyncValue<List<Meeting>>>((ref) {
  final meetingsAsync = ref.watch(meetingNotifierProvider);
  final today = DateTime.now();
  
  return meetingsAsync.when(
    data: (meetings) {
      final todaysMeetings = meetings.where((meeting) {
        final meetingDate = meeting.dateTime;
        return meetingDate.year == today.year &&
               meetingDate.month == today.month &&
               meetingDate.day == today.day &&
               !meeting.isCompleted;
      }).toList();
      return AsyncValue.data(todaysMeetings);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});