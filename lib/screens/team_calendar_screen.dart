import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/team_event.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class TeamCalendarScreen extends StatefulWidget {
  final String teamId;
  final String churchId;

  const TeamCalendarScreen({
    super.key,
    required this.teamId,
    required this.churchId,
  });

  @override
  State<TeamCalendarScreen> createState() => _TeamCalendarScreenState();
}

class _TeamCalendarScreenState extends State<TeamCalendarScreen> {
  final _firebaseService = FirebaseService();
  final _dateFormat = DateFormat('h:mm a');
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TeamEvent>> _events = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Calendar'),
      ),
      body: StreamBuilder<List<TeamEvent>>(
        stream: _firebaseService.getTeamEvents(
          widget.churchId,
          widget.teamId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading events'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Group events by day
          _events = {};
          for (final event in snapshot.data!) {
            final day = DateTime(
              event.startTime.year,
              event.startTime.month,
              event.startTime.day,
            );
            _events[day] = [...(_events[day] ?? []), event];
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _events[day] ?? [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('Select a day to view events'))
                    : ListView.builder(
                        itemCount: (_events[_selectedDay!] ?? []).length,
                        itemBuilder: (context, index) {
                          final event = _events[_selectedDay!]![index];
                          return ListTile(
                            title: Text(event.title),
                            subtitle: Text(
                              '${_dateFormat.format(event.startTime)} - ${event.location}',
                            ),
                            trailing: event.recurrenceType != RecurrenceType.none
                                ? const Icon(Icons.repeat)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
} 