class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final String userName;
  final String role;
  final DateTime joinedAt;
  final bool isActive;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'userId': userId,
      'userName': userName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      role: map['role'] ?? '',
      joinedAt: DateTime.parse(map['joinedAt']),
      isActive: map['isActive'] ?? true,
    );
  }
} 