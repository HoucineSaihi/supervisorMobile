import 'dart:convert';
import 'dart:html'; // Import for web localStorage
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SecureStorageService {
  // Save login data to localStorage
  Future<void> saveLoginData(Map<String, dynamic> data) async {
    window.localStorage['token'] = data['token'];
    window.localStorage['expires'] = data['expires'];
    window.localStorage['currentUserId'] = data['currentUserId'].toString();
    window.localStorage['currentName'] = data['currentName'];
    window.localStorage['role'] = data['role'].toString();
    window.localStorage['idBoutique'] = data['idBoutique']?.toString() ?? '';
  }

  // Retrieve token from localStorage
  Future<String?> getToken() async {
    return window.localStorage['token'];
  }

  // Retrieve login data from localStorage
  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': window.localStorage['token'],
      'expires': window.localStorage['expires'],
      'currentUserId': window.localStorage['currentUserId'],
      'currentName': window.localStorage['currentName'],
      'role': window.localStorage['role'],
      'idBoutique': window.localStorage['idBoutique'],
    };
  }

  // Clear all stored data in localStorage
  Future<void> clear() async {
    window.localStorage.clear();
  }
}

class LoginService {
  final String _baseURL = '${dotenv.env['BASE_URL']}/api/Caisses/login';
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
