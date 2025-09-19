
import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';

// ✅ Correct paths and file names (lowercase)
import '../utils/Helpers/secure_storage_data.dart'; // ✅ Correct SecureStorageService import

class DioService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://fd425a16cf1b.ngrok-free.app'
          '/api', // ⚡ Replace with your real API URL http://shopconnect.exoticgroup.net:8080/api
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
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
