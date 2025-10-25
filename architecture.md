# SoulWinning App Architecture

## Core Features Implementation

### 1. Database Layer (SQLite)
- **Member Model**: id, name, phone, address, notes, groupTag, createdAt, lastContact
- **Meeting Model**: id, title, description, dateTime, memberIds, isCompleted
- **FollowUp Model**: id, memberId, type, dueDate, isCompleted, notes
- **SMSTemplate Model**: id, name, content, category

### 2. Services Layer
- **DatabaseService**: SQLite operations using sqflite
- **SMSService**: ArkESel API integration for SMS sending
- **NotificationService**: Local notifications for reminders
- **ContactsService**: Save member contacts to device

### 3. State Management
- **Riverpod** for reactive state management
- **Providers** for members, meetings, follow-ups, and settings

### 4. UI Structure
- **Dashboard**: Stats overview, quick actions, overdue items
- **Members**: List/grid view, add/edit forms, group filtering
- **Meetings**: Calendar view, scheduler, SMS automation
- **Follow-ups**: List view with filtering, completion tracking
- **SMS**: Templates management, bulk messaging
- **Settings**: API key configuration, notification settings

### 5. Key Features
- Offline-first architecture with local SQLite storage
- Auto-SMS via ArkESel API when meetings scheduled
- Follow-up automation with local push notifications
- Contact saving integration
- CSV export capability
- Dark/light theme toggle

### 6. File Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── member.dart
│   ├── meeting.dart
│   ├── followup.dart
│   └── sms_template.dart
├── services/
│   ├── database_service.dart
│   ├── sms_service.dart
│   ├── notification_service.dart
│   └── contacts_service.dart
├── providers/
│   ├── member_provider.dart
│   ├── meeting_provider.dart
│   ├── followup_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── members_screen.dart
│   ├── meetings_screen.dart
│   ├── followups_screen.dart
│   ├── sms_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── member_card.dart
    ├── meeting_card.dart
    ├── stats_card.dart
    └── custom_app_bar.dart
```

### 7. Dependencies
- sqflite: Local SQLite database
- riverpod: State management
- http: ArkESel SMS API calls
- flutter_local_notifications: Push notifications
- contacts_service: Save to device contacts
- intl: Date formatting
- path: Database path handling