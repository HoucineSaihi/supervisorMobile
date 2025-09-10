
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supervisormobile/Interceptors/loading_interceptor.dart';

class LoadingManager {
  static LoadingInterceptor? _loadingInterceptor;

  // Initialize the loading interceptor
  static void initialize(LoadingInterceptor interceptor) {
    _loadingInterceptor = interceptor;
    print('✅ LoadingManager: Initialized successfully');
  }

  // Get the current loading interceptor instance
  static LoadingInterceptor? get instance => _loadingInterceptor;

  // Check if the loading interceptor is ready
  static bool get isReady => _loadingInterceptor != null;

  // Add an endpoint to exclude from loading spinner
  static void excludeEndpoint(String endpoint) {
    _loadingInterceptor?.addExcludedEndpoint(endpoint);
    print('📝 LoadingManager: Excluded endpoint: $endpoint');
  }

  // Remove an endpoint from exclusion list
  static void includeEndpoint(String endpoint) {
    _loadingInterceptor?.removeExcludedEndpoint(endpoint);
    print('📝 LoadingManager: Included endpoint: $endpoint');
  }

  // Clear all excluded endpoints
  static void clearExcludedEndpoints() {
    _loadingInterceptor?.clearExcludedEndpoints();
    print('📝 LoadingManager: Cleared all excluded endpoints');
  }

  // Get all currently excluded endpoints
  static List<String> get excludedEndpoints {
    // For now, return empty list to avoid compilation issues
    // This can be implemented later if needed
    return [];
  }

  // Test method to manually trigger loading
  static void testLoading() {
    _loadingInterceptor?.testShowLoading();
  }

  // Set the current cancel token for cancellation support
  static void setCurrentCancelToken(CancelToken? cancelToken, VoidCallback? onCancelPressed) {
    LoadingInterceptor.setCurrentCancelToken(cancelToken, onCancelPressed);
    print('🔄 LoadingManager: Set cancel token for current request');
  }

  // Cancel the current request
  static void cancelCurrentRequest() {
    LoadingInterceptor.cancelCurrentRequest();
    print('🚫 LoadingManager: Cancelled current request');
  }

  // Check if there's a cancellable request in progress
  static bool get hasCancellableRequest {
    return LoadingInterceptor.hasCancellableRequest;
  }
}