
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as dio;

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:shared_preferences/shared_preferences.dart'; // For Web fallback
import 'package:supervisormobile/services/DioService.dart';
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
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await DioService.dio.post(
        '/Caisses/login', // ✅ Relative path
        data: {
          'username': username,
          'passwd': password,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success']) {
          await _storageService.saveLoginData(data);
          return data;
        } else {
          throw Exception('Login failed: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }
}
