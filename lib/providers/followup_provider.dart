import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/models/followup.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/services/database_service.dart';
import 'package:harvestflow/services/notification_service.dart';

final overdueFollowUpsProvider = FutureProvider<List<FollowUp>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getOverdueFollowUps();
});

class FollowUpNotifier extends StateNotifier<AsyncValue<List<FollowUp>>> {
  FollowUpNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadFollowUps();
  }

  final DatabaseService _databaseService;
  final NotificationService _notificationService = NotificationService();

  Future<void> loadFollowUps() async {
    try {
      state = const AsyncValue.loading();
      final followUps = await _databaseService.getFollowUps();
      state = AsyncValue.data(followUps);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addFollowUp(FollowUp followUp, String memberName, {bool scheduleNotification = true}) async {
    try {
      final id = await _databaseService.insertFollowUp(followUp);
      
      if (scheduleNotification) {
        final followUpWithId = followUp.copyWith(id: id);
        await _notificationService.scheduleFollowUpReminder(followUpWithId, memberName);
      }
      
      await loadFollowUps();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateFollowUp(FollowUp followUp, String memberName, {bool rescheduleNotification = true}) async {
    try {
      await _databaseService.updateFollowUp(followUp);
      
      if (rescheduleNotification && followUp.id != null) {
        await _notificationService.cancelFollowUpNotification(followUp.id!);
        if (!followUp.isCompleted) {
          await _notificationService.scheduleFollowUpReminder(followUp, memberName);
        }
      }
      
      await loadFollowUps();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteFollowUp(int id) async {
    try {
      await _databaseService.deleteFollowUp(id);
      await _notificationService.cancelFollowUpNotification(id);
      await loadFollowUps();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeFollowUp(int id) async {
    try {
      final followUps = await _databaseService.getFollowUps();
      final followUp = followUps.firstWhere((f) => f.id == id);
      final completedFollowUp = followUp.copyWith(isCompleted: true);
      
      // Get member name for notification cancellation
      final member = await _databaseService.getMemberById(followUp.memberId);
      final memberName = member?.name ?? 'Member';
      
      await updateFollowUp(completedFollowUp, memberName, rescheduleNotification: true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final followUpNotifierProvider = StateNotifierProvider<FollowUpNotifier, AsyncValue<List<FollowUp>>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return FollowUpNotifier(databaseService);
});

final pendingFollowUpsProvider = Provider<AsyncValue<List<FollowUp>>>((ref) {
  final followUpsAsync = ref.watch(followUpNotifierProvider);
  
  return followUpsAsync.when(
    data: (followUps) {
      final pending = followUps.where((followUp) => !followUp.isCompleted).toList();
      return AsyncValue.data(pending);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final overdueCountProvider = Provider<AsyncValue<int>>((ref) {
  final followUpsAsync = ref.watch(followUpNotifierProvider);
  
  return followUpsAsync.when(
    data: (followUps) {
      final overdueCount = followUps.where((followUp) => followUp.isOverdue).length;
      return AsyncValue.data(overdueCount);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});