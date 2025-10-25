class Meeting {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final List<int> memberIds;
  final bool isCompleted;
  final bool smsSent;

  const Meeting({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.memberIds,
    this.isCompleted = false,
    this.smsSent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'memberIds': memberIds.join(','),
      'isCompleted': isCompleted ? 1 : 0,
      'smsSent': smsSent ? 1 : 0,
    };
  }

  static Meeting fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      memberIds: map['memberIds'] != null && map['memberIds'].isNotEmpty
          ? map['memberIds'].split(',').map<int>((id) => int.parse(id)).toList()
          : [],
      isCompleted: map['isCompleted'] == 1,
      smsSent: map['smsSent'] == 1,
    );
  }

  Meeting copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    List<int>? memberIds,
    bool? isCompleted,
    bool? smsSent,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      memberIds: memberIds ?? this.memberIds,
      isCompleted: isCompleted ?? this.isCompleted,
      smsSent: smsSent ?? this.smsSent,
    );
  }
}