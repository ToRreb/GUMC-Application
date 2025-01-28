import 'package:shared_preferences.dart';

class StorageService {
  static const String _churchKey = 'selected_church';
  static const String _userTypeKey = 'user_type';
  static const String _notificationsKey = 'notifications_enabled';
  
  final _prefs = SharedPreferences.getInstance();

  Future<void> saveSelectedChurch(String church) async {
    final prefs = await _prefs;
    await prefs.setString(_churchKey, church);
  }

  Future<String?> getSelectedChurch() async {
    final prefs = await _prefs;
    return prefs.getString(_churchKey);
  }

  Future<void> saveUserType(String userType) async {
    final prefs = await _prefs;
    await prefs.setString(_userTypeKey, userType);
  }

  Future<String?> getUserType() async {
    final prefs = await _prefs;
    return prefs.getString(_userTypeKey);
  }

  Future<void> clearUserData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_notificationsKey) ?? true; // Default to enabled
  }
} 