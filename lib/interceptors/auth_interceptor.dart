import 'package:dio/dio.dart';
import '../utils/Helpers/robust_storage_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Get the token from robust storage
      final String? token = await RobustStorageService.read('token');
      
      if (token != null && token.isNotEmpty) {
        // Add Authorization header with Bearer token
        options.headers['Authorization'] = 'Bearer $token';
        print('🔑 AuthInterceptor: Token added to request headers (using ${RobustStorageService.isUsingSecureStorage ? "SecureStorage" : "SharedPreferences"})');
      } else {
        print('⚠️ AuthInterceptor: No token found in storage');
      }
    } catch (e) {
      print('❌ AuthInterceptor: Error fetching token: $e');
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
