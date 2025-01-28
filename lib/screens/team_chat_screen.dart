import 'package:flutter/material.dart';
import '../models/team_message.dart';
import '../models/ministry_team.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamChatScreen extends StatefulWidget {
  final MinistryTeam team;
  final bool isAdmin;

  const TeamChatScreen({
    super.key,
    required this.team,
    required this.isAdmin,
  });

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _messageController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  final _dateFormat = DateFormat('MMM d, h:mm a');
  bool _isAnnouncement = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _firebaseService.sendTeamMessage(
      widget.team.churchId,
      widget.team.id,
      _messageController.text.trim(),
      isAnnouncement: _isAnnouncement,
    );

    _messageController.clear();
    setState(() {
      _isAnnouncement = false;
    });
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final url = await _firebaseService.uploadTeamMessageAttachment(
      widget.team.churchId,
      widget.team.id,
      fileName,
      bytes,
    );

    await _firebaseService.sendTeamMessage(
      widget.team.churchId,
      widget.team.id,
      _messageController.text.trim(),
      isAnnouncement: _isAnnouncement,
      attachmentUrl: url,
      attachmentType: 'image',
      attachmentName: fileName,
    );

    _messageController.clear();
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final url = await _firebaseService.uploadTeamMessageAttachment(
      widget.team.churchId,
      widget.team.id,
      file.name,
      file.bytes!,
    );

    await _firebaseService.sendTeamMessage(
      widget.team.churchId,
      widget.team.id,
      _messageController.text.trim(),
      isAnnouncement: _isAnnouncement,
      attachmentUrl: url,
      attachmentType: 'file',
      attachmentName: file.name,
    );

    _messageController.clear();
  }

  Future<void> _editMessage(TeamMessage message) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      await _firebaseService.editTeamMessage(
        widget.team.churchId,
        widget.team.id,
        message.id,
        controller.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TeamMessage>>(
              stream: _firebaseService.getTeamMessages(
                widget.team.churchId,
                widget.team.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (message.isAnnouncement)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      '📢 Announcement',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(message.content),
                                    const SizedBox(height: 4),
                                    Text(
                                      'by ${message.senderName} • ${_dateFormat.format(message.timestamp)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: isCurrentUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isCurrentUser) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    child: Text(
                                      message.senderName[0].toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2)
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isCurrentUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (!isCurrentUser)
                                          Text(
                                            message.senderName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        if (message.attachmentUrl != null) ...[
                                          if (message.attachmentType == 'image')
                                            GestureDetector(
                                              onTap: () => launchUrl(Uri.parse(message.attachmentUrl!)),
                                              child: Image.network(
                                                message.attachmentUrl!,
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            ListTile(
                                              leading: const Icon(Icons.attach_file),
                                              title: Text(message.attachmentName ?? 'File'),
                                              onTap: () => launchUrl(Uri.parse(message.attachmentUrl!)),
                                            ),
                                        ],
                                        Text(message.content),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _dateFormat.format(message.timestamp),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            if (message.isEdited)
                                              Text(
                                                ' (edited)',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            if (isCurrentUser) ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 16),
                                                onPressed: () => _editMessage(message),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 16),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Delete Message'),
                                                      content: const Text(
                                                        'Are you sure you want to delete this message?',
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
                                                    await _firebaseService.deleteTeamMessage(
                                                      widget.team.churchId,
                                                      widget.team.id,
                                                      message.id,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (widget.isAdmin)
                    CheckboxListTile(
                      title: const Text('Send as Announcement'),
                      value: _isAnnouncement,
                      onChanged: (value) {
                        setState(() {
                          _isAnnouncement = value ?? false;
                        });
                      },
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickAndSendImage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _pickAndSendFile,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 