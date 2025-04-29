import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/Helpers/secure_storage_data.dart';

class ClientIdInterceptor extends Interceptor {
  final _storage = FlutterSecureStorage();


  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      String? userIdString;
      int? userId;

      if (kIsWeb) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userIdString = prefs.getString('currentUserId');
      } else {
        final _storage = FlutterSecureStorage();
        userIdString = await _storage.read(key: 'currentUserId');
      }

      if (userIdString != null ) {
        options.headers['X-ClientId'] = userIdString;
      } else {
        print('No currentUserId found in secure storage.');
      }
    } catch (e) {
      print('Error fetching clientId from secure storage: $e');
    }
    return super.onRequest(options, handler);
  }
}