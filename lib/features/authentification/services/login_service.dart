import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> data) async {
    await _storage.write(key: 'token', value: data['token']);
    await _storage.write(key: 'expires', value: data['expires']);
    await _storage.write(key: 'currentUserId', value: data['currentUserId'].toString());
    await _storage.write(key: 'currentName', value: data['currentName']);
    await _storage.write(key: 'role', value: data['role'].toString());
    await _storage.write(key: 'idBoutique', value: data['idBoutique']?.toString() ?? '');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': await _storage.read(key: 'token'),
      'expires': await _storage.read(key: 'expires'),
      'currentUserId': await _storage.read(key: 'currentUserId'),
      'currentName': await _storage.read(key: 'currentName'),
      'role': await _storage.read(key: 'role'),
      'idBoutique': await _storage.read(key: 'idBoutique'),
    };
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

class LoginService {
  final String _baseURL = '${dotenv.env['BASE_URL']}/api/Caisses/login';
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Define the expiry date for testing
    DateTime expiryDate = DateTime(2024, 11, 15, 12, 0, 0); // Today at 16:00

    // Check if the current date is past the expiry date
    if (DateTime.now().isAfter(expiryDate)) {
      throw Exception('The login is no longer valid.');
    }

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
