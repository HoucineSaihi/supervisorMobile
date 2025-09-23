import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/navigation_key.dart';
import '../utils/Helpers/robust_storage_service.dart';

class ClientIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final String? userIdString = await RobustStorageService.read('currentUserId');
      
      if (userIdString != null) {
        options.headers['X-ClientId'] = userIdString;
      } else {
        print('No currentUserId found in storage.');
      }
    } catch (e) {
      print('Error fetching clientId from storage: $e');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 429) {
      // 👉 Always show a static message (ignore Retry-After)

      // Show a snackbar using navigatorKey
      final context = navigatorKey.currentState?.overlay?.context;

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❗ Beaucoup de requêtes envoyées. Veuillez patienter.'),
            backgroundColor: Colors.red,
          ),
        );
      }


      print('⚠️ 429 Too Many Requests caught.');
    }

    super.onError(err, handler);
  }



}