class NotificationHistory {
  final String id;
  final String churchId;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isBatched;
  final int? batchSize;

  NotificationHistory({
    required this.id,
    required this.churchId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isBatched = false,
    this.batchSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'churchId': churchId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isBatched': isBatched,
      'batchSize': batchSize,
    };
  }

  factory NotificationHistory.fromMap(Map<String, dynamic> map) {
    return NotificationHistory(
      id: map['id'] ?? '',
      churchId: map['churchId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isBatched: map['isBatched'] ?? false,
      batchSize: map['batchSize'],
    );
  }
} 