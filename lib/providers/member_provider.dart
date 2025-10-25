import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final memberListProvider = FutureProvider<List<Member>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getMembers();
});

final membersByGroupProvider = FutureProvider.family<List<Member>, String>((ref, groupTag) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getMembersByGroup(groupTag);
});

class MemberNotifier extends StateNotifier<AsyncValue<List<Member>>> {
  MemberNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  final DatabaseService _databaseService;

  Future<void> loadMembers() async {
    try {
      state = const AsyncValue.loading();
      final members = await _databaseService.getMembers();
      state = AsyncValue.data(members);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMember(Member member) async {
    try {
      await _databaseService.insertMember(member);
      await loadMembers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMember(Member member) async {
    try {
      await _databaseService.updateMember(member);
      await loadMembers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      await _databaseService.deleteMember(id);
      await loadMembers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final memberNotifierProvider = StateNotifierProvider<MemberNotifier, AsyncValue<List<Member>>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return MemberNotifier(databaseService);
});

final selectedGroupFilterProvider = StateProvider<String?>((ref) => null);

final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final membersAsync = ref.watch(memberNotifierProvider);
  final selectedGroup = ref.watch(selectedGroupFilterProvider);

  return membersAsync.when(
    data: (members) {
      if (selectedGroup == null || selectedGroup.isEmpty) {
        return AsyncValue.data(members);
      }
      final filtered = members.where((member) => member.groupTag == selectedGroup).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});