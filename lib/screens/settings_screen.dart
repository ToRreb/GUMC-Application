import 'package:flutter/material.dart';
import '../models/church.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import 'church_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Church currentChurch;
  final bool isAdmin;

  const SettingsScreen({
    super.key,
    required this.currentChurch,
    required this.isAdmin,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageService = StorageService();
  final _firebaseService = FirebaseService();
  final _notificationService = NotificationService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _storageService.getNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await _storageService.setNotificationsEnabled(value);

    if (value) {
      await _notificationService.subscribeToChurch(widget.currentChurch.id);
    } else {
      await _notificationService.unsubscribeFromChurch(widget.currentChurch.id);
    }
  }

  Future<void> _regeneratePin() async {
    try {
      await _firebaseService.regenerateAdminPin(widget.currentChurch.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN regenerated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error regenerating PIN: $e')),
        );
      }
    }
  }

  Future<void> _changeChurch() async {
    final result = await Navigator.push<Church>(
      context,
      MaterialPageRoute(
        builder: (context) => ChurchSelectionScreen(
          isAdmin: widget.isAdmin,
          allowBack: true,
        ),
      ),
    );

    if (result != null && mounted) {
      await _storageService.saveSelectedChurch(result.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Current Church'),
            subtitle: Text(widget.currentChurch.name),
            trailing: TextButton(
              onPressed: _changeChurch,
              child: const Text('Change'),
            ),
          ),
          const Divider(),
          if (widget.isAdmin) ...[
            ListTile(
              title: const Text('Admin PIN'),
              subtitle: const Text('View or regenerate church admin PIN'),
              onTap: () => _showAdminPinDialog(),
            ),
            const Divider(),
          ],
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive updates about announcements and events'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminPinDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current PIN: ${widget.currentChurch.adminPin}'),
            const SizedBox(height: 16),
            const Text(
              'Note: Regenerating the PIN will require all admins to use the new PIN.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _regeneratePin();
            },
            child: const Text('Regenerate PIN'),
          ),
        ],
      ),
    );
  }
} 