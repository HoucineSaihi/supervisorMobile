
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'package:supervisormobile/services/DioService.dart';

class SecureStorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveLoginData(Map<String, dynamic> data) async {
    // Extract token and ensure it's a string (handle if it's a list)
    String? tokenValue;
    final tokenData = data['token'];
    if (tokenData is List && tokenData.isNotEmpty) {
      tokenValue = tokenData.first.toString();
    } else if (tokenData is String) {
      tokenValue = tokenData;
    } else {
      tokenValue = tokenData?.toString();
    }
    // Clean token: remove any brackets if present
    if (tokenValue != null) {
      tokenValue = tokenValue.replaceAll(RegExp(r'^\[|\]$'), '');
    }
    
    await _storage.write(key: 'token', value: tokenValue);
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
  final SecureStorageService _storageService = SecureStorageService();
  final dio.Dio _dio = DioService.dio; // ✅ Correct way: reuse existing Dio instance

  Future<Map<String, dynamic>> login(String username, String password, {dio.CancelToken? cancelToken}) async {
    try {
      final response = await _dio.post(
        '/Caisses/login',
        data: {
          'username': username,
          'passwd': password,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success']) {
          await _storageService.saveLoginData(data);
          return data;
        } else {
          throw Exception('Login failed');
        }
      } else {
        throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is dio.DioException && e.type == dio.DioExceptionType.cancel) {
        print('🚫 login: Request was cancelled');
        throw Exception('Request was cancelled');
      }
      print('Login error: $e');
      throw Exception('Login error: $e');
    }
  }
}
