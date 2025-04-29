import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/Helpers/secure_storage_data.dart';
import '../utils/Keys/navigation_key.dart';

class ClientIdInterceptor extends Interceptor {
  final _storage = FlutterSecureStorage();


  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final String? userIdString = await _storage.read(key: 'currentUserId'); // ✅ CORRECT
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

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 429) {
      // 👉 Always show a static message (ignore Retry-After)
      const waitMessage = 'Beaucoup de requêtes envoyées. Veuillez patienter une minute.';

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