import 'package:flutter/material.dart';
import '../models/prayer_request.dart';
import 'package:intl/intl.dart';

class PrayerRequestDetailScreen extends StatelessWidget {
  final PrayerRequest request;
  final bool isAdmin;
  final Function(bool)? onAnsweredToggle;
  final VoidCallback? onDelete;
  final _dateFormat = DateFormat('MMMM dd, yyyy hh:mm a');

  PrayerRequestDetailScreen({
    super.key,
    required this.request,
    this.isAdmin = false,
    this.onAnsweredToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Request'),
        actions: isAdmin
            ? [
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
                      onDelete?.call();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'By ${request.authorName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Submitted on ${_dateFormat.format(request.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (request.updatedAt != null)
              Text(
                'Updated on ${_dateFormat.format(request.updatedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (isAdmin)
              SwitchListTile(
                title: const Text('Mark as Answered'),
                value: request.isAnswered,
                onChanged: onAnsweredToggle,
              ),
            if (!isAdmin && request.isAnswered)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'This prayer has been answered',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 