import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For Web fallback
import 'package:http/http.dart' as http;
class SecureStorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> data) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('expires', data['expires']);
      await prefs.setString('currentUserId', data['currentUserId'].toString());
      await prefs.setString('currentName', data['currentName']);
      await prefs.setString('role', data['role'].toString());
      await prefs.setString('idBoutique', data['idBoutique']?.toString() ?? '');
    } else {
      await _secureStorage.write(key: 'token', value: data['token']);
      await _secureStorage.write(key: 'expires', value: data['expires']);
      await _secureStorage.write(key: 'currentUserId', value: data['currentUserId'].toString());
      await _secureStorage.write(key: 'currentName', value: data['currentName']);
      await _secureStorage.write(key: 'role', value: data['role'].toString());
      await _secureStorage.write(key: 'idBoutique', value: data['idBoutique']?.toString() ?? '');
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } else {
      return await _secureStorage.read(key: 'token');
    }
  }

  Future<Map<String, String?>> getLoginData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return {
        'token': prefs.getString('token'),
        'expires': prefs.getString('expires'),
        'currentUserId': prefs.getString('currentUserId'),
        'currentName': prefs.getString('currentName'),
        'role': prefs.getString('role'),
        'idBoutique': prefs.getString('idBoutique'),
      };
    } else {
      return {
        'token': await _secureStorage.read(key: 'token'),
        'expires': await _secureStorage.read(key: 'expires'),
        'currentUserId': await _secureStorage.read(key: 'currentUserId'),
        'currentName': await _secureStorage.read(key: 'currentName'),
        'role': await _secureStorage.read(key: 'role'),
        'idBoutique': await _secureStorage.read(key: 'idBoutique'),
      };
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }
}


class LoginService {
  final String _baseURL = 'http://shopconnect.exoticgroup.net:8080/api/Caisses/login';
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(_baseURL),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'passwd': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success']) {
        await _storageService.saveLoginData(data);
        return data;
      } else {
        throw Exception('Login failed');
      }
    } else {
      throw Exception('Failed to connect to the server');
    }
  }
}
