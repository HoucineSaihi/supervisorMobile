import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LoadingInterceptor extends Interceptor {
  int _requestCount = 0;
  OverlayEntry? _overlayEntry;
  static OverlayState? _overlayState;
  static CancelToken? _currentCancelToken;
  static VoidCallback? _onCancelPressed;

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

  // Set the current cancel token and callback
  static void setCurrentCancelToken(CancelToken? cancelToken, VoidCallback? onCancelPressed) {
    _currentCancelToken = cancelToken;
    _onCancelPressed = onCancelPressed;
  }

  // Cancel the current request
  static void cancelCurrentRequest() {
    if (_currentCancelToken != null && !_currentCancelToken!.isCancelled) {
      _currentCancelToken!.cancel('User cancelled request');
      print('🚫 LoadingInterceptor: Request cancelled by user');
    }
    _currentCancelToken = null;
    _onCancelPressed = null;
  }

  // Check if there's a cancellable request in progress
  static bool get hasCancellableRequest {
    return _currentCancelToken != null && !_currentCancelToken!.isCancelled;
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
          child: Center(
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
                      _loadingMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Show cancel button if there's a cancel token available
                    if (_currentCancelToken != null && !_currentCancelToken!.isCancelled) ...[
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          cancelCurrentRequest();
                          _hideLoading();
                        },
                        icon: Icon(Icons.cancel, size: 16),
                        label: Text('Annuler'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
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
        // Clear cancel token when hiding loading
        _currentCancelToken = null;
        _onCancelPressed = null;
        print('✅ LoadingInterceptor: Loading overlay removed successfully');
      } catch (e) {
        print('❌ LoadingInterceptor: Error hiding loading overlay: $e');
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🔄 LoadingInterceptor: Request to ${options.path}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
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