import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:dio/dio.dart' as dio;
import 'package:supervisormobile/services/DioService.dart';

class UserService {
  static String get _baseUrl => "http://shopconnect.exoticgroup.net:8080";
  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;
  static final dio.Dio _dio = DioService.dio;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }
  Future<UserModel?> getUserById() async {
    try {
      String? userIdString;
      int? userId;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        userIdString = prefs.getString('currentUserId');
      } else {
        final _storage = const FlutterSecureStorage();
        userIdString = await _storage.read(key: 'currentUserId');
      }

      userId = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      final response = await _dio.get(
        '/Caisses/$userId', // ✅ Relative path, no need to construct manually
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        print('❌ Failed to load user. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error loading user: $e');
      return null;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      final response = await _dio.put(
        '/Caisses/$_currentUserID', // ✅ Relative path only
        queryParameters: {
          'updatePassword': false, // ✅ Send it cleanly as a query parameter
        },
        data: user.toJson(), // ✅ Directly send the JSON object
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
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
      print('❌ Error updating user: $e');
      return false;
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/Files', // ✅ Relative path
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['file']; // ✅ Correct key
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }
}
