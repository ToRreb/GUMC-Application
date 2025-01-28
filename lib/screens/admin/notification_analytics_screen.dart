import 'package:flutter/material.dart';
import '../../models/church.dart';
import '../../models/notification_history.dart';
import '../../models/notification_analytics.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class NotificationAnalyticsScreen extends StatelessWidget {
  final Church church;
  final _firebaseService = FirebaseService();
  final _dateFormat = DateFormat('MMM dd, yyyy');

  NotificationAnalyticsScreen({
    super.key,
    required this.church,
  });

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChart(Map<String, int> byType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...byType.entries.map((entry) {
              final total = byType.values.reduce((a, b) => a + b);
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: entry.value,
                        child: Container(
                          height: 24,
                          color: Colors.blue,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${entry.key} ($percentage%)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: total - entry.value,
                        child: Container(height: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Analytics'),
      ),
      body: StreamBuilder<List<NotificationHistory>>(
        stream: _firebaseService.getNotificationHistory(church.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = NotificationAnalytics.fromNotifications(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Sent',
                      analytics.totalSent.toString(),
                      Icons.notifications,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      'Batched',
                      analytics.totalBatched.toString(),
                      Icons.batch_prediction,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg Batch Size',
                      analytics.averageBatchSize.toStringAsFixed(1),
                      Icons.analytics,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      'Last Sent',
                      _dateFormat.format(analytics.lastSent),
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTypeChart(analytics.byType),
            ],
          );
        },
      ),
    );
  }
} 