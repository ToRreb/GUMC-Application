class TeamMessage {
  final String id;
  final String teamId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isAnnouncement;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;
  final bool isEdited;

  TeamMessage({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isAnnouncement = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.isEdited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isAnnouncement': isAnnouncement,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'attachmentName': attachmentName,
      'isEdited': isEdited,
    };
  }

  factory TeamMessage.fromMap(Map<String, dynamic> map) {
    return TeamMessage(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isAnnouncement: map['isAnnouncement'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      attachmentName: map['attachmentName'],
      isEdited: map['isEdited'] ?? false,
    );
  }
} 