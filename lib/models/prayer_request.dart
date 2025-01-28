class PrayerRequest {
  final String id;
  final String churchId;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAnswered;

  PrayerRequest({
    required this.id,
    required this.churchId,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isAnswered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'churchId': churchId,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAnswered': isAnswered,
    };
  }

  factory PrayerRequest.fromMap(Map<String, dynamic> map) {
    return PrayerRequest(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isAnswered: map['isAnswered'] ?? false,
    );
  }
} 