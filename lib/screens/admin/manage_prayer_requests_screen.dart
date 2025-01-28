import 'package:flutter/material.dart';
import '../../models/prayer_request.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ManagePrayerRequestsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  final _dateFormat = DateFormat('MMM dd, yyyy');

  ManagePrayerRequestsScreen({
    super.key,
    required this.churchId,
  });

  Future<void> _addPrayerRequest(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Prayer Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter prayer request title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter prayer request details',
              ),
              maxLines: 3,
            ),
          ],
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

    if (result == true && titleController.text.isNotEmpty) {
      final currentUser = _authService.currentUser;
      final request = PrayerRequest(
        id: '',
        churchId: churchId,
        title: titleController.text,
        description: descriptionController.text,
        authorId: currentUser?.uid ?? '',
        authorName: currentUser?.displayName ?? 'Admin',
        createdAt: DateTime.now(),
      );

      await _firebaseService.addPrayerRequest(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Prayer Requests'),
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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          request.isAnswered
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: request.isAnswered ? Colors.green : null,
                        ),
                        onPressed: () {
                          _firebaseService.markPrayerRequestAsAnswered(
                            churchId,
                            request.id,
                            !request.isAnswered,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Prayer Request'),
                              content: const Text(
                                'Are you sure you want to delete this prayer request?',
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
                            await _firebaseService.deletePrayerRequest(
                              churchId,
                              request.id,
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
                        builder: (context) => PrayerRequestDetailScreen(
                          request: request,
                          isAdmin: true,
                          onAnsweredToggle: (value) {
                            _firebaseService.markPrayerRequestAsAnswered(
                              churchId,
                              request.id,
                              value,
                            );
                          },
                          onDelete: () {
                            _firebaseService.deletePrayerRequest(
                              churchId,
                              request.id,
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
        onPressed: () => _addPrayerRequest(context),
        child: const Icon(Icons.add),
      ),
    );
  }
} 