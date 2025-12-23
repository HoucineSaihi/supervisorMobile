import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final _storage = FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Get the token from secure storage
      String? token = await _storage.read(key: 'token');
      
      if (token != null && token.isNotEmpty) {
        // Clean token: remove any brackets if present (safety check)
        token = token.replaceAll(RegExp(r'^\[|\]$'), '').trim();
        
        // Add Authorization header with Bearer token
        options.headers['Authorization'] = 'Bearer $token';
        print('🔑 AuthInterceptor: Token added to request headers');
      } else {
        print('⚠️ AuthInterceptor: No token found in secure storage');
      }
    } catch (e) {
      print('❌ AuthInterceptor: Error fetching token from secure storage: $e');
    }
    
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401) {
      print('🚫 AuthInterceptor: 401 Unauthorized - Token may be expired');
      // You could add logic here to redirect to login or refresh token
    }
    
    super.onError(err, handler);
  }
}
