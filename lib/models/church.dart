class Church {
  final String id;
  final String name;
  final String address;
  final String adminPin;
  final DateTime createdAt;

  Church({
    required this.id,
    required this.name,
    required this.address,
    required this.adminPin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'adminPin': adminPin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Church.fromMap(Map<String, dynamic> map) {
    return Church(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      adminPin: map['adminPin'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 