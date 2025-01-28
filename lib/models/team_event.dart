enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

class TeamEvent {
  final String id;
  final String teamId;
  final String churchId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String location;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final List<String> attendees;
  final bool isActive;
  final RecurrenceType recurrenceType;
  final int? recurrenceInterval; // e.g., every 2 weeks
  final DateTime? recurrenceEndDate;
  final List<int>? weeklyDays; // 0-6 for Sunday-Saturday
  final int? monthlyDay; // 1-31
  final String? parentEventId; // For recurring event instances

  TeamEvent({
    required this.id,
    required this.teamId,
    required this.churchId,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    List<String>? attendees,
    this.isActive = true,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.weeklyDays,
    this.monthlyDay,
    this.parentEventId,
  }) : attendees = attendees ?? [];

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'churchId': churchId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
      'attendees': attendees,
      'isActive': isActive,
      'recurrenceType': recurrenceType.toString(),
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'weeklyDays': weeklyDays,
      'monthlyDay': monthlyDay,
      'parentEventId': parentEventId,
    };
  }

  factory TeamEvent.fromMap(Map<String, dynamic> map) {
    return TeamEvent(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      churchId: map['churchId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      location: map['location'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      attendees: List<String>.from(map['attendees'] ?? []),
      isActive: map['isActive'] ?? true,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == map['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      recurrenceInterval: map['recurrenceInterval'],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      weeklyDays: map['weeklyDays'] != null
          ? List<int>.from(map['weeklyDays'])
          : null,
      monthlyDay: map['monthlyDay'],
      parentEventId: map['parentEventId'],
    );
  }

  DateTime? getNextOccurrence() {
    if (recurrenceType == RecurrenceType.none) return null;

    final interval = recurrenceInterval ?? 1;
    final now = DateTime.now();
    DateTime nextDate;

    switch (recurrenceType) {
      case RecurrenceType.daily:
        nextDate = startTime.add(Duration(days: interval));
        break;
      case RecurrenceType.weekly:
        if (weeklyDays != null && weeklyDays!.isNotEmpty) {
          // Find next weekday in the list
          var currentWeekday = now.weekday % 7;
          var nextWeekday = weeklyDays!
              .firstWhere((day) => day > currentWeekday,
                  orElse: () => weeklyDays!.first);
          var daysToAdd = nextWeekday > currentWeekday
              ? nextWeekday - currentWeekday
              : 7 - currentWeekday + nextWeekday;
          nextDate = startTime.add(Duration(days: daysToAdd));
        } else {
          nextDate = startTime.add(Duration(days: 7 * interval));
        }
        break;
      case RecurrenceType.monthly:
        if (monthlyDay != null) {
          var nextMonth = startTime.month + interval;
          var nextYear = startTime.year;
          while (nextMonth > 12) {
            nextMonth -= 12;
            nextYear++;
          }
          nextDate = DateTime(nextYear, nextMonth, monthlyDay!);
        } else {
          nextDate = DateTime(
            startTime.year,
            startTime.month + interval,
            startTime.day,
          );
        }
        break;
      case RecurrenceType.yearly:
        nextDate = DateTime(
          startTime.year + interval,
          startTime.month,
          startTime.day,
        );
        break;
      default:
        return null;
    }

    if (recurrenceEndDate != null && nextDate.isAfter(recurrenceEndDate!)) {
      return null;
    }

    return nextDate;
  }
} 