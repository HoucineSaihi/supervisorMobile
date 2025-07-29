import '../interceptors/loading_interceptor.dart';

class LoadingManager {
  static LoadingInterceptor? _loadingInterceptor;

  // Initialize the loading interceptor
  static void initialize(LoadingInterceptor interceptor) {
    _loadingInterceptor = interceptor;
  }

  // Get the current loading interceptor instance
  static LoadingInterceptor? get instance => _loadingInterceptor;

  // Add an endpoint to exclude from loading spinner
  static void excludeEndpoint(String endpoint) {
    _loadingInterceptor?.addExcludedEndpoint(endpoint);
  }

  // Remove an endpoint from exclusion list
  static void includeEndpoint(String endpoint) {
    _loadingInterceptor?.removeExcludedEndpoint(endpoint);
  }

  // Clear all excluded endpoints
  static void clearExcludedEndpoints() {
    _loadingInterceptor?.clearExcludedEndpoints();
  }

  // Get all currently excluded endpoints
  static List<String> get excludedEndpoints {
    // This would need to be implemented in the LoadingInterceptor class
    // For now, we'll return an empty list
    return [];
  }
} 