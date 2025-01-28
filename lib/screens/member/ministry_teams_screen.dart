import 'package:flutter/material.dart';
import '../../models/ministry_team.dart';
import '../../services/firebase_service.dart';
import '../../screens/ministry_team_detail_screen.dart';

class MinistryTeamsScreen extends StatelessWidget {
  final String churchId;
  final _firebaseService = FirebaseService();

  MinistryTeamsScreen({
    super.key,
    required this.churchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Teams'),
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
            return const Center(child: Text('No ministry teams available'));
          }

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              if (!team.isActive) return const SizedBox.shrink();
              
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
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MinistryTeamDetailScreen(
                          team: team,
                          isAdmin: false,
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
    );
  }
} 