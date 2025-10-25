// import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/models/meeting.dart';
import 'package:harvestflow/models/followup.dart';
import 'package:harvestflow/models/sms_template.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'soulwinning.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create members table
    await db.execute('''
      CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT NOT NULL,
        groupTag TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        lastContact INTEGER
      )
    ''');

    // Create meetings table
    await db.execute('''
      CREATE TABLE meetings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime INTEGER NOT NULL,
        memberIds TEXT,
        isCompleted INTEGER DEFAULT 0,
        smsSent INTEGER DEFAULT 0
      )
    ''');

    // Create follow-ups table
    await db.execute('''
      CREATE TABLE followups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId INTEGER NOT NULL,
        type TEXT NOT NULL,
        dueDate INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        notes TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');

    // Create SMS templates table
    await db.execute('''
      CREATE TABLE sms_templates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Insert default SMS templates
    for (var template in DefaultSMSTemplates.templates) {
      await db.insert('sms_templates', template.toMap());
    }

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample members
    final sampleMembers = [
      Member(
        name: 'John Smith',
        phone: '233501234567',
        address: 'Accra, Ghana',
        notes: 'New convert, very enthusiastic about Bible study',
        groupTag: GroupTags.newConvert,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Member(
        name: 'Mary Johnson',
        phone: '233241234568',
        address: 'Kumasi, Ghana',
        notes: 'Regular attendee, interested in baptism',
        groupTag: GroupTags.pendingBaptism,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        lastContact: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Member(
        name: 'David Wilson',
        phone: '233541234569',
        address: 'Tema, Ghana',
        notes: 'Part of weekly Bible study group',
        groupTag: GroupTags.bibleStudyGroup,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastContact: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Member(
        name: 'Sarah Brown',
        phone: '233261234570',
        address: 'Takoradi, Ghana',
        notes: 'First-time visitor, showed interest',
        groupTag: GroupTags.visitor,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    for (var member in sampleMembers) {
      await db.insert('members', member.toMap());
    }

    // Sample meetings
    final sampleMeetings = [
      Meeting(
        title: 'Bible Study',
        description: 'Weekly Bible study on the Gospel of John',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        memberIds: [1, 2, 3],
      ),
      Meeting(
        title: 'Prayer Meeting',
        description: 'Community prayer and fellowship',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        memberIds: [1, 2, 3, 4],
      ),
    ];

    for (var meeting in sampleMeetings) {
      await db.insert('meetings', meeting.toMap());
    }

    // Sample follow-ups
    final sampleFollowUps = [
      FollowUp(
        memberId: 1,
        type: FollowUpTypes.weekly,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        notes: 'Check on Bible study progress',
        createdAt: DateTime.now(),
      ),
      FollowUp(
        memberId: 4,
        type: FollowUpTypes.daily,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Follow up on first visit',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    for (var followUp in sampleFollowUps) {
      await db.insert('followups', followUp.toMap());
    }
  }

  // Member operations
  Future<List<Member>> getMembers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('members', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Member.fromMap(maps[i]));
  }

  Future<Member?> getMemberById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('members', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Member.fromMap(maps.first) : null;
  }

  Future<List<Member>> getMembersByGroup(String groupTag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('members', where: 'groupTag = ?', whereArgs: [groupTag]);
    return List.generate(maps.length, (i) => Member.fromMap(maps[i]));
  }

  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert('members', member.toMap());
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update('members', member.toMap(), where: 'id = ?', whereArgs: [member.id]);
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // Meeting operations
  Future<List<Meeting>> getMeetings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('meetings', orderBy: 'dateTime ASC');
    return List.generate(maps.length, (i) => Meeting.fromMap(maps[i]));
  }

  Future<List<Meeting>> getUpcomingMeetings() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'meetings',
      where: 'dateTime >= ? AND isCompleted = 0',
      whereArgs: [now],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) => Meeting.fromMap(maps[i]));
  }

  Future<int> insertMeeting(Meeting meeting) async {
    final db = await database;
    return await db.insert('meetings', meeting.toMap());
  }

  Future<int> updateMeeting(Meeting meeting) async {
    final db = await database;
    return await db.update('meetings', meeting.toMap(), where: 'id = ?', whereArgs: [meeting.id]);
  }

  Future<int> deleteMeeting(int id) async {
    final db = await database;
    return await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }

  // Follow-up operations
  Future<List<FollowUp>> getFollowUps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('followups', orderBy: 'dueDate ASC');
    return List.generate(maps.length, (i) => FollowUp.fromMap(maps[i]));
  }

  Future<List<FollowUp>> getOverdueFollowUps() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'followups',
      where: 'dueDate < ? AND isCompleted = 0',
      whereArgs: [now],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => FollowUp.fromMap(maps[i]));
  }

  Future<int> insertFollowUp(FollowUp followUp) async {
    final db = await database;
    return await db.insert('followups', followUp.toMap());
  }

  Future<int> updateFollowUp(FollowUp followUp) async {
    final db = await database;
    return await db.update('followups', followUp.toMap(), where: 'id = ?', whereArgs: [followUp.id]);
  }

  Future<int> deleteFollowUp(int id) async {
    final db = await database;
    return await db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }

  // SMS template operations
  Future<List<SMSTemplate>> getSMSTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sms_templates', orderBy: 'category, name');
    return List.generate(maps.length, (i) => SMSTemplate.fromMap(maps[i]));
  }

  Future<int> insertSMSTemplate(SMSTemplate template) async {
    final db = await database;
    return await db.insert('sms_templates', template.toMap());
  }

  Future<int> updateSMSTemplate(SMSTemplate template) async {
    final db = await database;
    return await db.update('sms_templates', template.toMap(), where: 'id = ?', whereArgs: [template.id]);
  }

  Future<int> deleteSMSTemplate(int id) async {
    final db = await database;
    return await db.delete('sms_templates', where: 'id = ?', whereArgs: [id]);
  }

  // Dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    final db = await database;

    final memberCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM members')) ?? 0;
    final meetingCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM meetings WHERE dateTime >= ? AND isCompleted = 0', [DateTime.now().millisecondsSinceEpoch])) ?? 0;
    final overdueCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM followups WHERE dueDate < ? AND isCompleted = 0', [DateTime.now().millisecondsSinceEpoch])) ?? 0;
    final followUpCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM followups WHERE isCompleted = 0')) ?? 0;

    return {
      'totalMembers': memberCount,
      'upcomingMeetings': meetingCount,
      'overdueFollowUps': overdueCount,
      'pendingFollowUps': followUpCount,
    };
  }
}