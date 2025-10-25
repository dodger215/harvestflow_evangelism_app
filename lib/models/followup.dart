class FollowUp {
  final int? id;
  final int memberId;
  final String type;
  final DateTime dueDate;
  final bool isCompleted;
  final String notes;
  final DateTime createdAt;

  const FollowUp({
    this.id,
    required this.memberId,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'type': type,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static FollowUp fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'],
      memberId: map['memberId'],
      type: map['type'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  FollowUp copyWith({
    int? id,
    int? memberId,
    String? type,
    DateTime? dueDate,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
  }) {
    return FollowUp(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isCompleted;
}

class FollowUpTypes {
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String monthly = 'Monthly';
  static const String prayer = 'Prayer';
  static const String bibleStudy = 'Bible Study';
  static const String pastoral = 'Pastoral Care';
  static const String evangelism = 'Evangelism';

  static List<String> get all => [
    daily,
    weekly,
    monthly,
    prayer,
    bibleStudy,
    pastoral,
    evangelism,
  ];
}