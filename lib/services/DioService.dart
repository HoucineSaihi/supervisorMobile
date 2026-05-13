import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';
import 'package:supervisormobile/interceptors/accept_language_interceptor.dart';
import 'package:supervisormobile/interceptors/auth_interceptor.dart';

class DioService {
  static const String _baseUrl = 'http://192.168.2.57:7070';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: '$_baseUrl/api',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ),
  )..interceptors.addAll([
      AuthInterceptor(),
      ClientIdInterceptor(),
      AcceptLanguageInterceptor(),
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);

  static String get assetsBaseUrl => _baseUrl;

  // Test method to demonstrate API call
  static Future<void> testApiCall() async {
    try {
      print('🧪 DioService: Testing API call...');
      await dio.get('/test-endpoint');
      print('✅ DioService: API call completed successfully');
    } catch (e) {
      print('❌ DioService: API call failed: $e');
    }
  }
}
/*connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),*/
