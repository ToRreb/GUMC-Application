class Event {
  final String id;
  final String churchId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  Event({
    required this.id,
    required this.churchId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'churchId': churchId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      location: map['location'] ?? '',
    );
  }
} 