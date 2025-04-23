import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For FlutterSecureStorage (non-web)
import 'dart:html' as html; // For web-specific localStorage handling

class SecureStorageService {
  // Check if we are on web and use localStorage for web
  bool get isWeb => kIsWeb;

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> data) async {
    if (isWeb) {
      // Storing data in localStorage for web
      html.window.localStorage['token'] = data['token'] ?? '';
      html.window.localStorage['expires'] = data['expires'] ?? '';
      html.window.localStorage['currentUserId'] = data['currentUserId'].toString();
      html.window.localStorage['currentName'] = data['currentName'] ?? '';
      html.window.localStorage['role'] = data['role']?.toString() ?? '';
      html.window.localStorage['idBoutique'] = data['idBoutique']?.toString() ?? '';
    } else {
      // Handle secure storage for mobile/desktop (FlutterSecureStorage)
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'expires', value: data['expires']);
      await _storage.write(key: 'currentUserId', value: data['currentUserId'].toString());
      await _storage.write(key: 'currentName', value: data['currentName']);
      await _storage.write(key: 'role', value: data['role']?.toString() ?? '');
      await _storage.write(key: 'idBoutique', value: data['idBoutique']?.toString() ?? '');
    }
  }

  Future<String?> getToken() async {
    if (isWeb) {
      return html.window.localStorage['token'];
    } else {
      // Handle secure storage for mobile/desktop (FlutterSecureStorage)
      return await _storage.read(key: 'token');
    }
  }

  Future<Map<String, String?>> getLoginData() async {
    if (isWeb) {
      return {
        'token': html.window.localStorage['token'],
        'expires': html.window.localStorage['expires'],
        'currentUserId': html.window.localStorage['currentUserId'],
        'currentName': html.window.localStorage['currentName'],
        'role': html.window.localStorage['role'],
        'idBoutique': html.window.localStorage['idBoutique'],
      };
    } else {
      // Handle secure storage for mobile/desktop (FlutterSecureStorage)
      return {
        'token': await _storage.read(key: 'token'),
        'expires': await _storage.read(key: 'expires'),
        'currentUserId': await _storage.read(key: 'currentUserId'),
        'currentName': await _storage.read(key: 'currentName'),
        'role': await _storage.read(key: 'role'),
        'idBoutique': await _storage.read(key: 'idBoutique'),
      };
    }
  }

  Future<void> clear() async {
    if (isWeb) {
      html.window.localStorage.clear();
    } else {
      // Handle secure storage for mobile/desktop (FlutterSecureStorage)
      await _storage.deleteAll();
    }
  }
}
