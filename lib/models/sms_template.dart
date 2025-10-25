class SMSTemplate {
  final int? id;
  final String name;
  final String content;
  final String category;

  const SMSTemplate({
    this.id,
    required this.name,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'category': category,
    };
  }

  static SMSTemplate fromMap(Map<String, dynamic> map) {
    return SMSTemplate(
      id: map['id'],
      name: map['name'],
      content: map['content'],
      category: map['category'],
    );
  }

  SMSTemplate copyWith({
    int? id,
    String? name,
    String? content,
    String? category,
  }) {
    return SMSTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      category: category ?? this.category,
    );
  }
}

class SMSTemplateCategories {
  static const String followUp = 'Follow-Up';
  static const String invitation = 'Invitation';
  static const String reminder = 'Reminder';
  static const String encouragement = 'Encouragement';
  static const String prayer = 'Prayer';
  static const String meeting = 'Meeting';

  static List<String> get all => [
    followUp,
    invitation,
    reminder,
    encouragement,
    prayer,
    meeting,
  ];
}

class DefaultSMSTemplates {
  static List<SMSTemplate> get templates => [
    const SMSTemplate(
      name: 'Meeting Reminder',
      content: 'Hi {name}, this is a reminder about our meeting: {title} on {date} at {time}. Looking forward to seeing you!',
      category: SMSTemplateCategories.meeting,
    ),
    const SMSTemplate(
      name: 'Follow-Up Check',
      content: 'Hello {name}, hope you are doing well! Just checking in to see how you are doing. God bless you!',
      category: SMSTemplateCategories.followUp,
    ),
    const SMSTemplate(
      name: 'Prayer Meeting Invitation',
      content: 'Dear {name}, you are invited to our prayer meeting on {date} at {time}. Come and join us in fellowship!',
      category: SMSTemplateCategories.invitation,
    ),
    const SMSTemplate(
      name: 'Bible Study Reminder',
      content: 'Hi {name}, reminder about our Bible study session tomorrow at {time}. Bring your Bible and an open heart!',
      category: SMSTemplateCategories.reminder,
    ),
    const SMSTemplate(
      name: 'Encouragement Message',
      content: 'Hello {name}, remember that God loves you and has great plans for your life! Stay blessed and keep the faith!',
      category: SMSTemplateCategories.encouragement,
    ),
    const SMSTemplate(
      name: 'Prayer Request',
      content: 'Hi {name}, we are praying for you today. If you have any prayer requests, please let us know. God is with you!',
      category: SMSTemplateCategories.prayer,
    ),
  ];
}