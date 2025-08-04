import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LoadingInterceptor extends Interceptor {
  int _requestCount = 0;
  OverlayEntry? _overlayEntry;
  static OverlayState? _overlayState;

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

  // Set the overlay state globally
  static void setOverlayState(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  bool _shouldShowLoading(String path) {
    return !_excludedEndpoints.any((endpoint) => path.contains(endpoint));
  }

  // Test method to manually trigger loading
  void testShowLoading() {
    print('🧪 LoadingInterceptor: Testing manual loading trigger');
    _showLoading();

    // Auto-hide after 3 seconds for testing
    Future.delayed(const Duration(seconds: 3), () {
      _hideLoading();
    });
  }

  void _showLoading() {
    print('🔄 LoadingInterceptor: Attempting to show loading...');
    if (_requestCount == 0) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Material(
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

      // Try to insert the overlay using the global overlay state
      if (_overlayState != null) {
        try {
          _overlayState!.insert(_overlayEntry!);
          print('✅ LoadingInterceptor: Loading overlay inserted successfully');
        } catch (e) {
          print('❌ LoadingInterceptor: Error showing loading overlay: $e');
        }
      } else {
        print('❌ LoadingInterceptor: Global overlay state is null');
      }
    }
    _requestCount++;
    print('🔄 LoadingInterceptor: Request count: $_requestCount');
  }

  void _hideLoading() {
    _requestCount--;
    print('🔄 LoadingInterceptor: Hiding loading, request count: $_requestCount');
    if (_requestCount == 0) {
      try {
        _overlayEntry?.remove();
        _overlayEntry = null;
        print('✅ LoadingInterceptor: Loading overlay removed successfully');
      } catch (e) {
        print('❌ LoadingInterceptor: Error hiding loading overlay: $e');
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🔄 LoadingInterceptor: Request to ${options.path}');
    if (_shouldShowLoading(options.path)) {
      _showLoading();
    } else {
      print('⏭️ LoadingInterceptor: Skipping loading for ${options.path}');
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