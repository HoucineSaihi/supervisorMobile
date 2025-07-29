import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/navigation_key.dart';

class LoadingInterceptor extends Interceptor {
  int _requestCount = 0;
  OverlayEntry? _overlayEntry;
  
  // List of endpoints that should not show loading spinner
  final List<String> _excludedEndpoints = [
    // Add endpoints here that shouldn't show loading
    // '/api/health',
    // '/api/status',
  ];

  // Customizable loading message
  final String _loadingMessage;

  LoadingInterceptor({String loadingMessage = 'Chargement...'}) 
      : _loadingMessage = loadingMessage;

  bool _shouldShowLoading(String path) {
    return !_excludedEndpoints.any((endpoint) => path.contains(endpoint));
  }

  void _showLoading() {
    if (_requestCount == 0) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Chargement...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final context = navigatorKey.currentState?.overlay?.context;
      if (context != null) {
        try {
          Overlay.of(context).insert(_overlayEntry!);
        } catch (e) {
          print('Error showing loading overlay: $e');
        }
      }
    }
    _requestCount++;
  }

  void _hideLoading() {
    _requestCount--;
    if (_requestCount == 0) {
      try {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } catch (e) {
        print('Error hiding loading overlay: $e');
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldShowLoading(options.path)) {
      _showLoading();
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldShowLoading(response.requestOptions.path)) {
      _hideLoading();
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldShowLoading(err.requestOptions.path)) {
      _hideLoading();
    }
    return super.onError(err, handler);
  }

  // Method to add excluded endpoints dynamically
  void addExcludedEndpoint(String endpoint) {
    if (!_excludedEndpoints.contains(endpoint)) {
      _excludedEndpoints.add(endpoint);
    }
  }

  // Method to remove excluded endpoints
  void removeExcludedEndpoint(String endpoint) {
    _excludedEndpoints.remove(endpoint);
  }

  // Method to clear all excluded endpoints
  void clearExcludedEndpoints() {
    _excludedEndpoints.clear();
  }
} 