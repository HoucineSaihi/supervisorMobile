import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets [Accept-Language] from the same [language_code] persisted by [LanguageController].
class AcceptLanguageInterceptor extends Interceptor {
  static const _prefsKey = 'language_code';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey) ?? 'en';
      options.headers['Accept-Language'] =
          code == 'fr' ? 'fr-FR' : 'en-US';
    } catch (_) {
      options.headers['Accept-Language'] = 'en-US';
    }
    handler.next(options);
  }
}
