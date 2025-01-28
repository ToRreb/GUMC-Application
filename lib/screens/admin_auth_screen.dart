import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminAuthScreen extends StatefulWidget {
  final String selectedChurch;
  
  const AdminAuthScreen({
    super.key, 
    required this.selectedChurch,
  });

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  bool _hasAccount = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selected Church: ${widget.selectedChurch}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            if (_hasAccount)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminLoginScreen(
                        selectedChurch: widget.selectedChurch,
                      ),
                    ),
                  );
                },
                child: const Text('Login'),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminSignupScreen(
                        selectedChurch: widget.selectedChurch,
                      ),
                    ),
                  );
                },
                child: const Text('Sign Up'),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasAccount = !_hasAccount;
                });
              },
              child: Text(
                _hasAccount
                    ? 'Need to create an account?'
                    : 'Already have an account?',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 