import 'package:flutter/material.dart';
import '../../models/bible_study_group.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../bible_study_group_detail_screen.dart';

class ManageBibleStudyGroupsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();
  final _authService = AuthService();

  ManageBibleStudyGroupsScreen({
    super.key,
    required this.churchId,
  });

  Future<void> _addBibleStudyGroup(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController();
    final locationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Bible Study Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter group description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Time',
                  hintText: 'e.g., Every Sunday at 10 AM',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter meeting location',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final currentUser = _authService.currentUser;
      final group = BibleStudyGroup(
        id: '',
        churchId: churchId,
        name: nameController.text,
        description: descriptionController.text,
        leaderId: currentUser?.uid ?? '',
        leaderName: currentUser?.displayName ?? 'Admin',
        meetingTime: timeController.text,
        location: locationController.text,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addBibleStudyGroup(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bible Study Groups'),
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
            return const Center(child: Text('No Bible study groups yet'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          group.isActive
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: group.isActive ? Colors.green : null,
                        ),
                        onPressed: () {
                          _firebaseService.toggleBibleStudyGroupStatus(
                            churchId,
                            group.id,
                            !group.isActive,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Bible Study Group'),
                              content: const Text(
                                'Are you sure you want to delete this group?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _firebaseService.deleteBibleStudyGroup(
                              churchId,
                              group.id,
                            );
                          }
                        },
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
                          isAdmin: true,
                          onActiveToggle: (value) {
                            _firebaseService.toggleBibleStudyGroupStatus(
                              churchId,
                              group.id,
                              value,
                            );
                          },
                          onDelete: () {
                            _firebaseService.deleteBibleStudyGroup(
                              churchId,
                              group.id,
                            );
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBibleStudyGroup(context),
        child: const Icon(Icons.add),
      ),
    );
  }
} 