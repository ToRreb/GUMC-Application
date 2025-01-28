import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/firebase_service.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  final String churchId;

  const ManageAnnouncementsScreen({
    super.key,
    required this.churchId,
  });

  @override
  State<ManageAnnouncementsScreen> createState() => _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final _firebaseService = FirebaseService();

  Future<void> _showAddEditDialog([Announcement? announcement]) async {
    final titleController = TextEditingController(text: announcement?.title);
    final contentController = TextEditingController(text: announcement?.content);
    DateTime? expiryDate = announcement?.expiresAt;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement == null ? 'Add Announcement' : 'Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(expiryDate?.toString() ?? 'No expiry date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: expiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => expiryDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                return;
              }

              final newAnnouncement = Announcement(
                id: announcement?.id ?? '',
                churchId: widget.churchId,
                title: titleController.text,
                content: contentController.text,
                createdAt: announcement?.createdAt ?? DateTime.now(),
                expiresAt: expiryDate,
              );

              if (announcement == null) {
                await _firebaseService.addAnnouncement(newAnnouncement);
              } else {
                await _firebaseService.updateAnnouncement(newAnnouncement);
              }

              if (mounted) Navigator.pop(context);
            },
            child: Text(announcement == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: _firebaseService.getAnnouncements(widget.churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(announcement.title),
                  subtitle: Text(
                    announcement.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showAddEditDialog(announcement);
                      } else if (value == 'delete') {
                        await _firebaseService.deleteAnnouncement(
                          widget.churchId,
                          announcement.id,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 