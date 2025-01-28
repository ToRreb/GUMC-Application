import 'package:flutter/material.dart';
import '../models/team_event.dart';
import '../models/ministry_team.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:your_app/widgets/loading_overlay.dart';
import 'package:your_app/widgets/error_view.dart';

class TeamEventsScreen extends StatefulWidget {
  final MinistryTeam team;
  final bool isAdmin;

  const TeamEventsScreen({
    super.key,
    required this.team,
    required this.isAdmin,
  });

  @override
  State<TeamEventsScreen> createState() => _TeamEventsScreenState();
}

class _TeamEventsScreenState extends State<TeamEventsScreen> {
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');
  RecurrenceType _recurrenceType = RecurrenceType.none;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  List<int> _selectedWeekDays = [];
  int? _selectedMonthDay;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _addEvent() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final titleController = TextEditingController();
      final descriptionController = TextEditingController();
      final locationController = TextEditingController();
      DateTime selectedDate = DateTime.now();
      TimeOfDay selectedTime = TimeOfDay.now();
      DateTime? selectedEndDate;
      TimeOfDay? selectedEndTime;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('New Team Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      hintText: 'Enter event title',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter event description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter event location',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_dateFormat.format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_timeFormat.format(DateTime(
                      2022,
                      1,
                      1,
                      selectedTime.hour,
                      selectedTime.minute,
                    ))),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Add End Time'),
                    value: selectedEndDate != null,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedEndDate = selectedDate;
                          selectedEndTime = TimeOfDay.fromDateTime(
                            selectedDate.add(const Duration(hours: 1)),
                          );
                        } else {
                          selectedEndDate = null;
                          selectedEndTime = null;
                        }
                      });
                    },
                  ),
                  if (selectedEndDate != null) ...[
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_dateFormat.format(selectedEndDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate!,
                          firstDate: selectedDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedEndDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_timeFormat.format(DateTime(
                        2022,
                        1,
                        1,
                        selectedEndTime!.hour,
                        selectedEndTime!.minute,
                      ))),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedEndTime!,
                        );
                        if (time != null) {
                          setState(() => selectedEndTime = time);
                        }
                      },
                    ),
                  ],
                  const Divider(height: 32),
                  _buildRecurrenceOptions(setState),
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
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );

      if (result == true) {
        final currentUser = _authService.currentUser;
        if (currentUser == null) return;

        final startDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        DateTime? endDateTime;
        if (selectedEndDate != null && selectedEndTime != null) {
          endDateTime = DateTime(
            selectedEndDate!.year,
            selectedEndDate!.month,
            selectedEndDate!.day,
            selectedEndTime!.hour,
            selectedEndTime!.minute,
          );
        }

        final event = TeamEvent(
          id: '',
          teamId: widget.team.id,
          churchId: widget.team.churchId,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          location: locationController.text.trim(),
          creatorId: currentUser.uid,
          creatorName: currentUser.displayName ?? 'Anonymous',
          createdAt: DateTime.now(),
          recurrenceType: _recurrenceType,
          recurrenceInterval: _recurrenceInterval,
          recurrenceEndDate: _recurrenceEndDate,
          weeklyDays: _recurrenceType == RecurrenceType.weekly
              ? _selectedWeekDays
              : null,
          monthlyDay: _recurrenceType == RecurrenceType.monthly
              ? _selectedMonthDay
              : null,
        );

        await _firebaseService.addTeamEvent(event);

        setState(() {
          _recurrenceType = RecurrenceType.none;
          _recurrenceInterval = 1;
          _recurrenceEndDate = null;
          _selectedWeekDays.clear();
          _selectedMonthDay = null;
        });
      }
    } on FirebaseOperationException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRecurrenceOptions(StateSetter setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          value: _recurrenceType,
          decoration: const InputDecoration(
            labelText: 'Repeat',
          ),
          items: RecurrenceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.toString().split('.').last.capitalize()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _recurrenceType = value!;
              if (value == RecurrenceType.none) {
                _recurrenceInterval = 1;
                _recurrenceEndDate = null;
                _selectedWeekDays.clear();
                _selectedMonthDay = null;
              }
            });
          },
        ),
        if (_recurrenceType != RecurrenceType.none) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _recurrenceInterval.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Repeat every',
                    suffixText: 'times',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceInterval = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(_getIntervalLabel()),
            ],
          ),
          if (_recurrenceType == RecurrenceType.weekly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Repeat on:'),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final weekday = index;
                      return FilterChip(
                        label: Text(_getWeekdayLabel(weekday)),
                        selected: _selectedWeekDays.contains(weekday),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekDays.add(weekday);
                            } else {
                              _selectedWeekDays.remove(weekday);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          if (_recurrenceType == RecurrenceType.monthly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: DropdownButtonFormField<int>(
                value: _selectedMonthDay,
                decoration: const InputDecoration(
                  labelText: 'Day of month',
                ),
                items: List.generate(31, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  setState(() => _selectedMonthDay = value);
                },
              ),
            ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(
              _recurrenceEndDate != null
                  ? _dateFormat.format(_recurrenceEndDate!)
                  : 'Never',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _recurrenceEndDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (date != null) {
                setState(() => _recurrenceEndDate = date);
              }
            },
          ),
        ],
      ],
    );
  }

  String _getIntervalLabel() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return 'days';
      case RecurrenceType.weekly:
        return 'weeks';
      case RecurrenceType.monthly:
        return 'months';
      case RecurrenceType.yearly:
        return 'years';
      default:
        return '';
    }
  }

  String _getWeekdayLabel(int day) {
    switch (day) {
      case 0:
        return 'Sun';
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.team.name} Events'),
          actions: [
            StreamBuilder<bool>(
              stream: GetIt.I<ConnectivityService>().connectionStream,
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? true;
                return Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.grey,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamCalendarScreen(
                      teamId: widget.team.id,
                      churchId: widget.team.churchId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: _errorMessage != null
            ? ErrorView(
                message: _errorMessage!,
                onRetry: () => setState(() => _errorMessage = null),
              )
            : StreamBuilder<List<TeamEvent>>(
                stream: _firebaseService.getTeamEvents(
                  widget.team.churchId,
                  widget.team.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading events'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data!;

                  if (events.isEmpty) {
                    return const Center(child: Text('No events scheduled'));
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isAttending =
                          event.attendees.contains(_authService.currentUser?.uid ?? '');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(event.title),
                              subtitle: Text(
                                '${_dateFormat.format(event.startTime)} at ${_timeFormat.format(event.startTime)}',
                              ),
                              trailing: widget.isAdmin
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Event'),
                                            content: const Text(
                                              'Are you sure you want to delete this event?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _firebaseService.deleteTeamEvent(
                                            widget.team.churchId,
                                            widget.team.id,
                                            event.id,
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.description.isNotEmpty) ...[
                                    Text(event.description),
                                    const SizedBox(height: 8),
                                  ],
                                  if (event.location.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Text(event.location),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    'Created by ${event.creatorName}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${event.attendees.length} attending',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => _firebaseService
                                            .toggleTeamEventAttendance(
                                          widget.team.churchId,
                                          widget.team.id,
                                          event.id,
                                        ),
                                        icon: Icon(
                                          isAttending
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                        ),
                                        label: Text(
                                          isAttending ? 'Attending' : 'Attend',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
        floatingActionButton: widget.isAdmin
            ? FloatingActionButton(
                onPressed: _addEvent,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
} 