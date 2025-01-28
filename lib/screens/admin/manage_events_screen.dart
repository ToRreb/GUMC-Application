import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class ManageEventsScreen extends StatefulWidget {
  final String churchId;

  const ManageEventsScreen({
    super.key,
    required this.churchId,
  });

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final _firebaseService = FirebaseService();
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _timeFormat = DateFormat('hh:mm a');

  Future<void> _showAddEditDialog([Event? event]) async {
    final titleController = TextEditingController(text: event?.title);
    final descriptionController = TextEditingController(text: event?.description);
    final locationController = TextEditingController(text: event?.location);
    DateTime startTime = event?.startTime ?? DateTime.now();
    DateTime endTime = event?.endTime ?? DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event == null ? 'Add Event' : 'Edit Event'),
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
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(
                  '${_dateFormat.format(startTime)} ${_timeFormat.format(startTime)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (time != null) {
                      setState(() {
                        startTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        if (endTime.isBefore(startTime)) {
                          endTime = startTime.add(const Duration(hours: 1));
                        }
                      });
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(
                  '${_dateFormat.format(endTime)} ${_timeFormat.format(endTime)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endTime,
                    firstDate: startTime,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endTime),
                    );
                    if (time != null) {
                      setState(() {
                        endTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
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
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  locationController.text.isEmpty) {
                return;
              }

              final newEvent = Event(
                id: event?.id ?? '',
                churchId: widget.churchId,
                title: titleController.text,
                description: descriptionController.text,
                startTime: startTime,
                endTime: endTime,
                location: locationController.text,
              );

              if (event == null) {
                await _firebaseService.addEvent(newEvent);
              } else {
                await _firebaseService.updateEvent(newEvent);
              }

              if (mounted) Navigator.pop(context);
            },
            child: Text(event == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
      ),
      body: StreamBuilder<List<Event>>(
        stream: _firebaseService.getEvents(widget.churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dateFormat.format(event.startTime)} ${_timeFormat.format(event.startTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        event.location,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                        await _showAddEditDialog(event);
                      } else if (value == 'delete') {
                        await _firebaseService.deleteEvent(
                          widget.churchId,
                          event.id,
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