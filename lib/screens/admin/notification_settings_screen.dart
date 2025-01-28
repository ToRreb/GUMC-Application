import 'package:flutter/material.dart';
import '../../models/church.dart';
import '../../services/firebase_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final Church church;

  const NotificationSettingsScreen({
    super.key,
    required this.church,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _firebaseService = FirebaseService();
  bool _enableReminders = true;
  bool _batchNotifications = false;
  int _batchInterval = 15;
  bool _enableQuietHours = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _firebaseService.getNotificationSettings(widget.church.id);
    setState(() {
      _enableReminders = settings['enableReminders'] ?? true;
      _batchNotifications = settings['batchNotifications'] ?? false;
      _batchInterval = settings['batchInterval'] ?? 15;
      _enableQuietHours = settings['quietHoursStart'] != null;
      if (_enableQuietHours) {
        _quietHoursStart = TimeOfDay(
          hour: settings['quietHoursStart'] as int,
          minute: 0,
        );
        _quietHoursEnd = TimeOfDay(
          hour: settings['quietHoursEnd'] as int,
          minute: 0,
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    await _firebaseService.updateNotificationSettings(
      widget.church.id,
      {
        'enableReminders': _enableReminders,
        'batchNotifications': _batchNotifications,
        'batchInterval': _batchInterval,
        if (_enableQuietHours) ...{
          'quietHoursStart': _quietHoursStart.hour,
          'quietHoursEnd': _quietHoursEnd.hour,
        },
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable Event Reminders'),
            subtitle: const Text('Send reminders before events'),
            value: _enableReminders,
            onChanged: (value) => setState(() => _enableReminders = value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Batch Notifications'),
            subtitle: const Text('Group multiple notifications together'),
            value: _batchNotifications,
            onChanged: (value) => setState(() => _batchNotifications = value),
          ),
          if (_batchNotifications)
            ListTile(
              title: const Text('Batch Interval'),
              subtitle: Text('${_batchInterval} minutes'),
              trailing: DropdownButton<int>(
                value: _batchInterval,
                items: [5, 15, 30, 60]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e min'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _batchInterval = value);
                  }
                },
              ),
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Pause notifications during specific hours'),
            value: _enableQuietHours,
            onChanged: (value) => setState(() => _enableQuietHours = value),
          ),
          if (_enableQuietHours) ...[
            ListTile(
              title: const Text('Quiet Hours Start'),
              subtitle: Text(_quietHoursStart.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietHoursStart,
                );
                if (time != null) {
                  setState(() => _quietHoursStart = time);
                }
              },
            ),
            ListTile(
              title: const Text('Quiet Hours End'),
              subtitle: Text(_quietHoursEnd.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietHoursEnd,
                );
                if (time != null) {
                  setState(() => _quietHoursEnd = time);
                }
              },
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        label: const Text('Save Settings'),
        icon: const Icon(Icons.save),
      ),
    );
  }
} 