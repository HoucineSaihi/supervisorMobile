
import 'package:dio/dio.dart';
import 'package:supervisormobile/interceptors/ClientIdInterceptor.dart';
import 'package:supervisormobile/interceptors/accept_language_interceptor.dart';
import 'package:supervisormobile/interceptors/auth_interceptor.dart';

class DioService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://149.202.58.46:7070/api', //
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
    AuthInterceptor(), // Add authentication interceptor first
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

  /// Returns API host without `/api` suffix.
  /// Example: `https://host/api` -> `https://host`
  static String get assetsBaseUrl {
    final rawBase = dio.options.baseUrl.trim();
    if (rawBase.isEmpty) return rawBase;

    final parsed = Uri.tryParse(rawBase);
    if (parsed == null || parsed.host.isEmpty) return rawBase;

    final path = parsed.path;
    final normalizedPath = path.endsWith('/api')
        ? path.substring(0, path.length - 4)
        : path;

    final rebuilt = parsed.replace(path: normalizedPath, query: '', fragment: '');
    final rebuiltString = rebuilt.toString();
    final noSuffix = rebuiltString
        .replaceFirst(RegExp(r'[?#]+$'), '')
        .replaceAll(RegExp(r'/$'), '');
    return noSuffix;
  }

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
