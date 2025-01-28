import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../models/church.dart';
import '../services/notification_service.dart';

class ChurchSelectionScreen extends StatefulWidget {
  final bool isAdmin;
  final bool allowBack;
  
  const ChurchSelectionScreen({
    super.key, 
    required this.isAdmin,
    this.allowBack = false,
  });

  @override
  State<ChurchSelectionScreen> createState() => _ChurchSelectionScreenState();
}

class _ChurchSelectionScreenState extends State<ChurchSelectionScreen> {
  final _searchController = TextEditingController();
  final _storageService = StorageService();
  final _firebaseService = FirebaseService();
  List<Church> filteredChurches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChurches();
  }

  void _loadChurches() {
    _firebaseService.getChurches().listen(
      (churches) {
        setState(() {
          filteredChurches = churches;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Error loading churches: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _filterChurches(String query) {
    setState(() {
      if (query.isEmpty) {
        _loadChurches();
      } else {
        filteredChurches = filteredChurches
            .where((church) => 
                church.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _selectChurch(Church church) async {
    await _storageService.saveSelectedChurch(church.id);
    
    // Subscribe to notifications for the selected church
    final notificationsEnabled = await _storageService.getNotificationsEnabled();
    if (notificationsEnabled) {
      await NotificationService().subscribeToChurch(church.id);
    }
    
    if (mounted) {
      if (widget.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminAuthScreen(selectedChurch: church),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemberDashboardScreen(selectedChurch: church),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Church'),
        automaticallyImplyLeading: widget.allowBack,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Church',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterChurches,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredChurches.length,
                  itemBuilder: (context, index) {
                    final church = filteredChurches[index];
                    return Card(
                      child: ListTile(
                        title: Text(church.name),
                        subtitle: Text(church.address),
                        onTap: () => _selectChurch(church),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 