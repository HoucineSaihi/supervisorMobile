import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';

class UserService {
  static String get _baseUrl => "http://shopconnect.exoticgroup.net:8080";
  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }
  Future<UserModel?> getUserById() async {
    String? userIdString;
    int? userId;

    if (kIsWeb) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userIdString = prefs.getString('currentUserId');
    } else {
      final _storage = FlutterSecureStorage();
      userIdString = await _storage.read(key: 'currentUserId');
    }


    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    final url = Uri.parse('$_baseUrl/api/Caisses/$_currentUserID');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load user');
      return null;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;
    final url = Uri.parse('$_baseUrl/api/Caisses/$_currentUserID?updatePassword=false');
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode(user.toJson()); // Assuming UserModel has a toJson method

    final response = await http.put(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
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
  }

  Future<String> uploadFile(File file) async {
    final Uri uri = Uri.parse('$_baseUrl/api/Files'); // Construct the URI for your file upload endpoint

    // Determine the MIME type based on the file extension
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    var request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = '*/*'
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(
        http.MultipartFile(
          'image', // Name of the file parameter in your API
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split('/').last,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);
      return responseData['file']; // Extract the filename from the response
    } else {
      throw Exception('Failed to upload file');
    }
  }
}
