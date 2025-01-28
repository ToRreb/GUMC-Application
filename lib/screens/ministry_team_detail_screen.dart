import 'package:flutter/material.dart';
import '../models/ministry_team.dart';
import 'package:intl/intl.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'team_chat_screen.dart';
import 'team_events_screen.dart';

class MinistryTeamDetailScreen extends StatelessWidget {
  final MinistryTeam team;
  final bool isAdmin;
  final Function(bool)? onActiveToggle;
  final VoidCallback? onDelete;
  final _dateFormat = DateFormat('MMMM dd, yyyy');
  final _firebaseService = FirebaseService();
  final _authService = AuthService();

  Future<void> _joinTeam(BuildContext context) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Role'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: team.roles.map((role) => ListTile(
              title: Text(role),
              onTap: () => Navigator.pop(context, role),
            )).toList(),
          ),
        ),
      ),
    );

    if (selectedRole != null) {
      await _firebaseService.joinTeam(team.churchId, team.id, selectedRole);
    }
  }

  Future<void> _leaveTeam(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.leaveTeam(team.churchId, team.id);
    }
  }

  Future<void> _changeRole(BuildContext context, TeamMember member) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: team.roles.map((role) => ListTile(
              title: Text(role),
              selected: role == member.role,
              onTap: () => Navigator.pop(context, role),
            )).toList(),
          ),
        ),
      ),
    );

    if (selectedRole != null && selectedRole != member.role) {
      await _firebaseService.updateTeamMemberRole(
        team.churchId,
        team.id,
        member.userId,
        selectedRole,
      );
    }
  }

  MinistryTeamDetailScreen({
    super.key,
    required this.team,
    this.isAdmin = false,
    this.onActiveToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Team'),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamEventsScreen(
                          team: team,
                          isAdmin: true,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamChatScreen(
                          team: team,
                          isAdmin: true,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Ministry Team'),
                        content: const Text(
                          'Are you sure you want to delete this team?',
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
              team.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Led by ${team.leaderName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(team.description),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Team Roles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: team.roles.map((role) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Text(role),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Current Members'),
                trailing: Text(
                  team.memberCount.toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Team Members',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<TeamMember>>(
              stream: _firebaseService.getTeamMembers(team.churchId, team.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading team members');
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data!;

                return Column(
                  children: [
                    Card(
                      child: Column(
                        children: members.map((member) => ListTile(
                          title: Text(member.userName),
                          subtitle: Text(member.role),
                          trailing: isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _dateFormat.format(member.joinedAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _changeRole(context, member),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Remove Member'),
                                            content: Text(
                                              'Are you sure you want to remove ${member.userName} from the team?',
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
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _firebaseService.removeTeamMember(
                                            team.churchId,
                                            team.id,
                                            member.userId,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : Text(
                                  _dateFormat.format(member.joinedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                        )).toList(),
                      ),
                    ),
                    if (!isAdmin) const SizedBox(height: 16),
                    if (!isAdmin)
                      FutureBuilder<bool>(
                        future: _firebaseService.isTeamMember(team.churchId, team.id),
                        builder: (context, snapshot) {
                          final isMember = snapshot.data ?? false;

                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          return ElevatedButton(
                            onPressed: team.isActive
                                ? () => isMember
                                    ? _leaveTeam(context)
                                    : _joinTeam(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMember ? Colors.red : null,
                            ),
                            child: Text(isMember ? 'Leave Team' : 'Join Team'),
                          );
                        },
                      ),
                    if (!isAdmin && team.isActive)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamChatScreen(
                                team: team,
                                isAdmin: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Team Chat'),
                      ),
                    if (!isAdmin && team.isActive)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamEventsScreen(
                                team: team,
                                isAdmin: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Team Events'),
                      ),
                  ],
                );
              },
            ),
            if (isAdmin)
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: Text(
                  team.isActive ? 'Team is active' : 'Team is inactive',
                ),
                value: team.isActive,
                onChanged: onActiveToggle,
              ),
            if (!isAdmin && !team.isActive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'This team is currently inactive',
                      style: TextStyle(color: Colors.red),
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