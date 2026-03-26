import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/services/DioService.dart';

class UserService {
  String _baseUrl = "${dotenv.env['BASE_URL']}"; // Replace with your actual base URL
  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;
  final dio.Dio _dio = DioService.dio; // ✅ Correct way: reuse existing Dio instance

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }
  Future<UserModel?> getUserById({dio.CancelToken? cancelToken}) async {
    try {
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      final response = await _dio.get(
        '/Caisses/$_currentUserID',
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final payload = response.data;
        final userJson = payload is Map<String, dynamic> && payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(payload as Map);
        return UserModel.fromJson(userJson);
      } else {
        print('Failed to load user. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is dio.DioException && e.type == dio.DioExceptionType.cancel) {
        print('🚫 getUserById: Request was cancelled');
        return null;
      }
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<bool> updateUser(UserModel user, {dio.CancelToken? cancelToken}) async {
    try {
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      final response = await _dio.put(
        '/Caisses/$_currentUserID',
        queryParameters: {
          'updatePassword': false,
        },
        data: user.toJson(),
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final responseData = response.data; // ✅ Already parsed
        if (responseData['success'] == true) {
          return true;
        } else {
          print('Failed to update user: ${responseData['message']}');
          return false;
        }
      } else {
        print('Failed to update user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException && e.type == dio.DioExceptionType.cancel) {
        print('🚫 updateUser: Request was cancelled');
        return false;
      }
      print('Error updating user: $e');
      return false;
    }
  }

  Future<String> uploadFile(File file, {dio.CancelToken? cancelToken}) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final mimeTypeParts = mimeType.split('/');

      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/Files',
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['file']; // ✅ Return the uploaded file name
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is dio.DioException && e.type == dio.DioExceptionType.cancel) {
        print('🚫 uploadFile: Request was cancelled');
        throw Exception('Request was cancelled');
      }
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }
}
