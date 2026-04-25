import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RobustStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  static bool _useSecureStorage = true;

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // Initialize the service
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web build: rely on SharedPreferences (backed by browser localStorage)
      _prefs = await SharedPreferences.getInstance();
      _useSecureStorage = false;
      print('🔐 RobustStorageService: Using SharedPreferences on web');
      return;
    }

    try {
      // Try to initialize secure storage
      await _secureStorage.read(key: 'test');
      _useSecureStorage = true;
      print('🔐 RobustStorageService: Using FlutterSecureStorage');
    } catch (e) {
      // Fallback to SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      _useSecureStorage = false;
      print('🔐 RobustStorageService: Using SharedPreferences fallback');
    }
  }

  // Write data
  static Future<void> write(String key, String value) async {
    try {
      if (_useSecureStorage) {
        await _secureStorage.write(key: key, value: value);
      } else {
        final prefs = await _getPrefs();
        await prefs.setString(key, value);
      }
    } catch (e) {
      // If secure storage fails, try SharedPreferences
      if (_useSecureStorage) {
        _useSecureStorage = false;
        final prefs = await _getPrefs();
        await prefs.setString(key, value);
        print('🔐 RobustStorageService: Switched to SharedPreferences due to error: $e');
      }
    }
  }

  // Read data
  static Future<String?> read(String key) async {
    try {
      if (_useSecureStorage) {
        return await _secureStorage.read(key: key);
      } else {
        final prefs = await _getPrefs();
        return prefs.getString(key);
      }
    } catch (e) {
      // If secure storage fails, try SharedPreferences
      if (_useSecureStorage) {
        _useSecureStorage = false;
        final prefs = await _getPrefs();
        final result = prefs.getString(key);
        print('🔐 RobustStorageService: Switched to SharedPreferences due to error: $e');
        return result;
      }
      return null;
    }
  }

  // Delete data
  static Future<void> delete(String key) async {
    try {
      if (_useSecureStorage) {
        await _secureStorage.delete(key: key);
      } else {
        final prefs = await _getPrefs();
        await prefs.remove(key);
      }
    } catch (e) {
      // If secure storage fails, try SharedPreferences
      if (_useSecureStorage) {
        _useSecureStorage = false;
        final prefs = await _getPrefs();
        await prefs.remove(key);
        print('🔐 RobustStorageService: Switched to SharedPreferences due to error: $e');
      }
    }
  }

  // Clear all data
  static Future<void> clear() async {
    try {
      if (_useSecureStorage) {
        await _secureStorage.deleteAll();
      } else {
        final prefs = await _getPrefs();
        await prefs.clear();
      }
    } catch (e) {
      // If secure storage fails, try SharedPreferences
      if (_useSecureStorage) {
        _useSecureStorage = false;
        final prefs = await _getPrefs();
        await prefs.clear();
        print('🔐 RobustStorageService: Switched to SharedPreferences due to error: $e');
      }
    }
  }

  // Check if using secure storage
  static bool get isUsingSecureStorage => _useSecureStorage;
}
