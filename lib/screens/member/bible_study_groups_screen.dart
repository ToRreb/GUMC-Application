import 'package:flutter/material.dart';
import '../../models/bible_study_group.dart';
import '../../services/firebase_service.dart';
import '../bible_study_group_detail_screen.dart';

class BibleStudyGroupsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();

  BibleStudyGroupsScreen({
    super.key,
    required this.churchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Study Groups'),
      ),
      body: StreamBuilder<List<BibleStudyGroup>>(
        stream: _firebaseService.getBibleStudyGroups(churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!;

          if (groups.isEmpty) {
            return const Center(child: Text('No Bible study groups available'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              if (!group.isActive) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.description),
                      const SizedBox(height: 4),
                      Text(
                        'Led by ${group.leaderName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Meets: ${group.meetingTime}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Location: ${group.location}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BibleStudyGroupDetailScreen(
                          group: group,
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