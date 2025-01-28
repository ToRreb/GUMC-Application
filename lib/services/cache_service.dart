import 'package:shared_preferences.dart';
import 'dart:convert';

class CacheService {
  final SharedPreferences _prefs;
  
  CacheService(this._prefs);
  
  static Future<CacheService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheService(prefs);
  }

  Future<void> cacheData(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  T? getCachedData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final data = _prefs.getString(key);
    if (data != null) {
      return fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> clearCache() async {
    await _prefs.clear();
  }
} 