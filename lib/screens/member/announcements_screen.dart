import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/firebase_service.dart';

class AnnouncementsScreen extends StatelessWidget {
  final String churchId;

  const AnnouncementsScreen({
    super.key,
    required this.churchId,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: firebaseService.getAnnouncements(churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data!;

          if (announcements.isEmpty) {
            return const Center(child: Text('No announcements yet'));
          }

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(announcement.content),
                      if (announcement.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Expires: ${announcement.expiresAt!.toString()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 