class NotificationAnalytics {
  final int totalSent;
  final Map<String, int> byType;
  final Map<String, int> byHour;
  final double averageBatchSize;
  final DateTime lastSent;
  final int totalBatched;

  NotificationAnalytics({
    required this.totalSent,
    required this.byType,
    required this.byHour,
    required this.averageBatchSize,
    required this.lastSent,
    required this.totalBatched,
  });

  factory NotificationAnalytics.fromNotifications(List<NotificationHistory> notifications) {
    final byType = <String, int>{};
    final byHour = <String, int>{};
    var batchedCount = 0;
    var totalBatchSize = 0;

    for (final notification in notifications) {
      // Count by type
      byType[notification.type] = (byType[notification.type] ?? 0) + 1;

      // Count by hour
      final hour = notification.timestamp.hour.toString().padLeft(2, '0');
      byHour[hour] = (byHour[hour] ?? 0) + 1;

      // Track batched notifications
      if (notification.isBatched) {
        batchedCount++;
        totalBatchSize += notification.batchSize ?? 1;
      }
    }

    return NotificationAnalytics(
      totalSent: notifications.length,
      byType: byType,
      byHour: byHour,
      averageBatchSize: batchedCount > 0 ? totalBatchSize / batchedCount : 0,
      lastSent: notifications.isNotEmpty ? notifications.first.timestamp : DateTime.now(),
      totalBatched: batchedCount,
    );
  }
} 