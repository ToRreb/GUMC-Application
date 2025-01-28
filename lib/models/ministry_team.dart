class MinistryTeam {
  final String id;
  final String churchId;
  final String name;
  final String description;
  final String leaderId;
  final String leaderName;
  final List<String> roles;  // Different roles within the team
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  MinistryTeam({
    required this.id,
    required this.churchId,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.leaderName,
    required this.roles,
    this.memberCount = 0,
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
      'roles': roles,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory MinistryTeam.fromMap(Map<String, dynamic> map) {
    return MinistryTeam(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leaderId: map['leaderId'] ?? '',
      leaderName: map['leaderName'] ?? '',
      roles: List<String>.from(map['roles'] ?? []),
      memberCount: map['memberCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
} 