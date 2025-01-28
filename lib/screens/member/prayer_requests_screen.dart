import 'package:flutter/material.dart';
import '../../models/prayer_request.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class PrayerRequestsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();
  final _dateFormat = DateFormat('MMM dd, yyyy');

  PrayerRequestsScreen({
    super.key,
    required this.churchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Requests'),
      ),
      body: StreamBuilder<List<PrayerRequest>>(
        stream: _firebaseService.getPrayerRequests(churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;

          if (requests.isEmpty) {
            return const Center(child: Text('No prayer requests yet'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(request.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.description),
                      const SizedBox(height: 4),
                      Text(
                        'By ${request.authorName} on ${_dateFormat.format(request.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (request.isAnswered)
                        Text(
                          'Prayer Answered',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrayerRequestDetailScreen(
                          request: request,
                          isAdmin: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 