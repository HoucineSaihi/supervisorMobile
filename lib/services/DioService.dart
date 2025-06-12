import 'package:dio/dio.dart';
import 'package:supervisormobile/Interceptors/ClientIdInterceptor.dart';

// ✅ Correct paths and file names (lowercase)
import '../utils/Helpers/secure_storage_data.dart'; // ✅ Correct SecureStorageService import

class DioService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.82:8080/api', // ⚡ Replace with your real API URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
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
}
