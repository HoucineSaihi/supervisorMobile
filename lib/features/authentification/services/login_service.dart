
import 'package:dio/dio.dart' as dio;
import 'package:supervisormobile/services/DioService.dart';
import 'package:supervisormobile/utils/Helpers/robust_storage_service.dart';

class SecureStorageService {
  Future<void> saveLoginData(Map<String, dynamic> data) async {
    final String token = (data['token'] ?? '').toString().trim();
    if (token.isEmpty) {
      throw Exception('Login succeeded but token is missing from response.');
    }

    await RobustStorageService.write('token', token);
    await RobustStorageService.write('expires', data['expires']);
    await RobustStorageService.write('currentUserId', data['currentUserId'].toString());
    await RobustStorageService.write('currentName', data['currentName']);
    await RobustStorageService.write('role', data['role'].toString());
    await RobustStorageService.write('idBoutique', data['idBoutique']?.toString() ?? '');
  }

  Future<String?> getToken() async {
    return await RobustStorageService.read('token');
  }

  Future<Map<String, String?>> getLoginData() async {
    return {
      'token': await RobustStorageService.read('token'),
      'expires': await RobustStorageService.read('expires'),
      'currentUserId': await RobustStorageService.read('currentUserId'),
      'currentName': await RobustStorageService.read('currentName'),
      'role': await RobustStorageService.read('role'),
      'idBoutique': await RobustStorageService.read('idBoutique'),
    };
  }

  Future<void> clear() async {
    await RobustStorageService.clear();
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

        if (data['success'] == true) {
          print('🔐 LoginService: Saving login data...');
          print('🔐 LoginService: Token received: ${data['token'] != null ? 'YES' : 'NO'}');
          await _storageService.saveLoginData(data);
          
          // Verify token was saved
          final savedToken = await _storageService.getToken();
          print('🔐 LoginService: Token saved successfully: ${savedToken != null ? 'YES' : 'NO'}');
          
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
