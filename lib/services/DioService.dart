
import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';
import 'package:supervisormobile/Interceptors/loading_interceptor.dart';
import 'package:supervisormobile/utils/loading_manager.dart';

// ✅ Correct paths and file names (lowercase)
import '../utils/Helpers/secure_storage_data.dart'; // ✅ Correct SecureStorageService import

class DioService {
  static final LoadingInterceptor _loadingInterceptor = LoadingInterceptor();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://c76129de4fa4.ngrok-free.app'
          '/api', // ⚡ Replace with your real API URL http://shopconnect.exoticgroup.net:8080/api
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
    _loadingInterceptor,
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

  // Initialize the loading manager
  static void initialize() {
    LoadingManager.initialize(_loadingInterceptor);
  }

  // Test method to demonstrate loading with API call
  static Future<void> testApiCall() async {
    try {
      print('🧪 DioService: Testing API call with loading...');
      // This will trigger the loading interceptor
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
