
import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';
import 'package:supervisormobile/interceptors/auth_interceptor.dart';

class DioService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://efbabcc0d83c.ngrok-free.app/api', // ✅ Using the real API URL
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
    AuthInterceptor(), // Add authentication interceptor first
    ClientIdInterceptor(),
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  ]);

  // Test method to demonstrate API call
  static Future<void> testApiCall() async {
    try {
      print('🧪 DioService: Testing API call...');
      final response = await dio.get('/test-endpoint');
      print('✅ DioService: API call completed successfully');
    } catch (e) {
      print('❌ DioService: API call failed: $e');
    }
  }
}
/*connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),*/
