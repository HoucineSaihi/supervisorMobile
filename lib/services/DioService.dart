import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';
import 'package:supervisormobile/interceptors/loading_interceptor.dart';
import 'package:supervisormobile/interceptors/auth_interceptor.dart';
import 'package:supervisormobile/utils/loading_manager.dart';

// ✅ Correct paths and file names (lowercase)
import '../utils/Helpers/secure_storage_data.dart'; // ✅ Correct SecureStorageService import

class DioService {
  static final LoadingInterceptor _loadingInterceptor = LoadingInterceptor();
  
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:7000'
          '/api', // ⚡ Replace with your real API URL http://shopconnect.exoticgroup.net:8080/api
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
    AuthInterceptor(), // Add authentication interceptor first
   // _loadingInterceptor,
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
}
/*connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),*/