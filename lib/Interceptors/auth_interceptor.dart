import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/services/SignalrNotificationService.dart';
import 'package:supervisormobile/utils/Keys/navigation_key.dart';

class AuthInterceptor extends Interceptor {
  final _storage = FlutterSecureStorage();

  static bool _sessionExpiryInProgress = false;

  static bool _isLoginRequest(RequestOptions options) {
    final path = options.path;
    return path.contains('Caisses/login');
  }

  void _disconnectOnUnauthorized(RequestOptions request) {
    if (_isLoginRequest(request)) return;
    unawaited(_disconnectExpiredSession());
  }

  Future<void> _disconnectExpiredSession() async {
    if (_sessionExpiryInProgress) return;
    _sessionExpiryInProgress = true;
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) return;

      await SignalrNotificationService.instance.disconnect();
      await _storage.deleteAll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = navigatorKey.currentState;
        if (nav != null && nav.mounted) {
          nav.pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
    } finally {
      _sessionExpiryInProgress = false;
    }
  }

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
    if (err.response?.statusCode == 401) {
      print('🚫 AuthInterceptor: 401 Unauthorized - clearing session and returning to login');
      _disconnectOnUnauthorized(err.requestOptions);
    }

    super.onError(err, handler);
  }
}
