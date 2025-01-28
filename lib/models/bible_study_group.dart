class BibleStudyGroup {
  final String id;
  final String churchId;
  final String name;
  final String description;
  final String leaderId;
  final String leaderName;
  final String meetingTime;
  final String location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  BibleStudyGroup({
    required this.id,
    required this.churchId,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.leaderName,
    required this.meetingTime,
    required this.location,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'churchId': churchId,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'meetingTime': meetingTime,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory BibleStudyGroup.fromMap(Map<String, dynamic> map) {
    return BibleStudyGroup(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leaderId: map['leaderId'] ?? '',
      leaderName: map['leaderName'] ?? '',
      meetingTime: map['meetingTime'] ?? '',
      location: map['location'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
} 