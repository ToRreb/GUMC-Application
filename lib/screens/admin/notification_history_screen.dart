import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/church.dart';
import '../../models/notification_history.dart';
import '../../services/firebase_service.dart';
import '../../screens/admin/notification_analytics_screen.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final Church church;
  final _firebaseService = FirebaseService();
  final _dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  final _searchController = TextEditingController();
  String _selectedType = 'all';
  List<NotificationHistory> _filteredNotifications = [];

  NotificationHistoryScreen({
    super.key,
    required this.church,
  });

  String _getTypeIcon(String type) {
    switch (type) {
      case 'announcement':
        return '📢';
      case 'event':
        return '📅';
      case 'reminder':
        return '⏰';
      default:
        return '📱';
    }
  }

  void _filterNotifications(List<NotificationHistory> notifications) {
    final query = _searchController.text.toLowerCase();
    _filteredNotifications = notifications.where((notification) {
      final matchesSearch = notification.title.toLowerCase().contains(query) ||
          notification.body.toLowerCase().contains(query);
      final matchesType = _selectedType == 'all' || notification.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationAnalyticsScreen(
                    church: church,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search notifications',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedType,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Types'),
                    ),
                    ...['announcement', 'event', 'reminder'].map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type[0].toUpperCase() + type.substring(1),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationHistory>>(
              stream: _firebaseService.getNotificationHistory(church.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data!;
                _filterNotifications(notifications);

                if (_filteredNotifications.isEmpty) {
                  return const Center(
                    child: Text('No matching notifications found'),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Text(
                          _getTypeIcon(notification.type),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(notification.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            const SizedBox(height: 4),
                            Text(
                              _dateFormat.format(notification.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (notification.isBatched)
                              Text(
                                'Batched notification (${notification.batchSize} items)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 