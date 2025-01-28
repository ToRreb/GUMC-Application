import 'package:flutter/material.dart';
import 'member_login_screen.dart';
import 'admin_login_screen.dart';
import '../services/storage_service.dart';
import '../screens/church_selection_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Title
                const Text(
                  'GUMC APP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Member Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () async {
                    await StorageService().saveUserType('member');
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChurchSelectionScreen(isAdmin: false),
                        ),
                      );
                    }
                  },
                  child: const Text('Member Login'),
                ),
                const SizedBox(height: 16),
                
                // Admin Login Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () async {
                    await StorageService().saveUserType('admin');
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChurchSelectionScreen(isAdmin: true),
                        ),
                      );
                    }
                  },
                  child: const Text('Admin Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 