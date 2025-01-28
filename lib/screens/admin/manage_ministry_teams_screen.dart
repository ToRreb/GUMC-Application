import 'package:flutter/material.dart';
import '../../models/ministry_team.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../screens/ministry_team_detail_screen.dart';

class ManageMinistryTeamsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();
  final _authService = AuthService();

  ManageMinistryTeamsScreen({
    super.key,
    required this.churchId,
  });

  Future<void> _addMinistryTeam(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final rolesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Ministry Team'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  hintText: 'Enter team name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter team description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rolesController,
                decoration: const InputDecoration(
                  labelText: 'Roles',
                  hintText: 'Enter roles (comma-separated)',
                ),
              ),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final currentUser = _authService.currentUser;
      final roles = rolesController.text
          .split(',')
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList();

      final team = MinistryTeam(
        id: '',
        churchId: churchId,
        name: nameController.text,
        description: descriptionController.text,
        leaderId: currentUser?.uid ?? '',
        leaderName: currentUser?.displayName ?? 'Admin',
        roles: roles,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addMinistryTeam(team);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Ministry Teams'),
      ),
      body: StreamBuilder<List<MinistryTeam>>(
        stream: _firebaseService.getMinistryTeams(churchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!;

          if (teams.isEmpty) {
            return const Center(child: Text('No ministry teams yet'));
          }

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(team.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.description),
                      const SizedBox(height: 4),
                      Text(
                        'Led by ${team.leaderName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Roles: ${team.roles.join(", ")}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Members: ${team.memberCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          team.isActive
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: team.isActive ? Colors.green : null,
                        ),
                        onPressed: () {
                          _firebaseService.toggleMinistryTeamStatus(
                            churchId,
                            team.id,
                            !team.isActive,
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
                            await _firebaseService.deleteMinistryTeam(
                              churchId,
                              team.id,
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
                        builder: (context) => MinistryTeamDetailScreen(
                          team: team,
                          isAdmin: true,
                          onActiveToggle: (value) {
                            _firebaseService.toggleMinistryTeamStatus(
                              churchId,
                              team.id,
                              value,
                            );
                          },
                          onDelete: () {
                            _firebaseService.deleteMinistryTeam(
                              churchId,
                              team.id,
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
        onPressed: () => _addMinistryTeam(context),
        child: const Icon(Icons.add),
      ),
    );
  }
} 