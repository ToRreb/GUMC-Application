class Announcement {
  final String id;
  final String churchId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Announcement({
    required this.id,
    required this.churchId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'churchId': churchId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt']) 
          : null,
    );
  }
} 