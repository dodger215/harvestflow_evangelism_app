import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/models/sms_template.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/services/database_service.dart';

final smsTemplatesProvider = FutureProvider<List<SMSTemplate>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getSMSTemplates();
});

class SMSTemplateNotifier extends StateNotifier<AsyncValue<List<SMSTemplate>>> {
  SMSTemplateNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadTemplates();
  }

  final DatabaseService _databaseService;

  Future<void> loadTemplates() async {
    try {
      state = const AsyncValue.loading();
      final templates = await _databaseService.getSMSTemplates();
      state = AsyncValue.data(templates);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTemplate(SMSTemplate template) async {
    try {
      await _databaseService.insertSMSTemplate(template);
      await loadTemplates();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTemplate(SMSTemplate template) async {
    try {
      await _databaseService.updateSMSTemplate(template);
      await loadTemplates();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTemplate(int id) async {
    try {
      await _databaseService.deleteSMSTemplate(id);
      await loadTemplates();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final smsTemplateNotifierProvider = StateNotifierProvider<SMSTemplateNotifier, AsyncValue<List<SMSTemplate>>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SMSTemplateNotifier(databaseService);
});

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void updateApiKey(String apiKey) {
    state = state.copyWith(arkEselApiKey: apiKey);
  }

  void updateSender(String sender) {
    state = state.copyWith(smsSender: sender);
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void toggleDarkMode(bool enabled) {
    state = state.copyWith(darkModeEnabled: enabled);
  }

  void toggleAutoSMS(bool enabled) {
    state = state.copyWith(autoSMSEnabled: enabled);
  }
}

class AppSettings {
  final String arkEselApiKey;
  final String smsSender;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool autoSMSEnabled;

  const AppSettings({
    this.arkEselApiKey = '',
    this.smsSender = 'SoulReach',
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.autoSMSEnabled = true,
  });

  AppSettings copyWith({
    String? arkEselApiKey,
    String? smsSender,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? autoSMSEnabled,
  }) {
    return AppSettings(
      arkEselApiKey: arkEselApiKey ?? this.arkEselApiKey,
      smsSender: smsSender ?? this.smsSender,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      autoSMSEnabled: autoSMSEnabled ?? this.autoSMSEnabled,
    );
  }
}

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getDashboardStats();
});