class Member {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final String groupTag;
  final DateTime createdAt;
  final DateTime? lastContact;

  const Member({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.groupTag,
    required this.createdAt,
    this.lastContact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'groupTag': groupTag,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastContact': lastContact?.millisecondsSinceEpoch,
    };
  }

  static Member fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      notes: map['notes'],
      groupTag: map['groupTag'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastContact: map['lastContact'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastContact'])
          : null,
    );
  }

  Member copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    String? groupTag,
    DateTime? createdAt,
    DateTime? lastContact,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      groupTag: groupTag ?? this.groupTag,
      createdAt: createdAt ?? this.createdAt,
      lastContact: lastContact ?? this.lastContact,
    );
  }
}

class GroupTags {
  static const String newConvert = 'New Convert';
  static const String bibleStudyGroup = 'Bible Study Group';
  static const String pendingBaptism = 'Pending Baptism';
  static const String regular = 'Regular';
  static const String followUp = 'Follow-Up';
  static const String visitor = 'Visitor';

  static List<String> get all => [
    newConvert,
    bibleStudyGroup,
    pendingBaptism,
    regular,
    followUp,
    visitor,
  ];
}