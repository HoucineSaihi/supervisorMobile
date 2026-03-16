import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/services/DioService.dart';
import '../dtos/vm_campaign_dto.dart';
import '../dtos/vm_guideline_asset_dto.dart';
import '../../calendar/models/boutiqueModel.dart';
import 'guideline_cache_manager.dart';

/// Service for Visual Merchandising API calls
class VmService {
  static final Dio _dio = DioService.dio;

  /// Get campaigns by site IDs
  /// POST /api/VmCompaign/by-sites
  /// Request body: [1, 2, 3] (array of site IDs)
  Future<List<VmCampaignDto>> getCampaignsBySites(List<int> siteIds) async {
    try {
      if (siteIds.isEmpty) {
        throw Exception('At least one site ID is required.');
      }

      if (kDebugMode) {
        final baseUrl = _dio.options.baseUrl;
        print('📡 VmService.getCampaignsBySites() → POST $baseUrl/VmCompaign/by-sites body=$siteIds');
      }

      final response = await _dio.post(
        '/VmCompaign/by-sites',
        data: siteIds,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = response.data;
        return jsonResponse
            .map((json) => VmCampaignDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load campaigns. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Request was cancelled');
      }
      if (e.response != null) {
        final message = e.response?.data['message'] as String?;
        throw Exception(message ?? 'An error occurred while fetching campaigns: ${e.message}');
      }
      throw Exception('An error occurred while fetching campaigns: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while fetching campaigns: $e');
    }
  }

  /// Get boutiques by user IDs
  /// POST /api/Boutiques/getBoutiquesByUserIDs
  /// Request body: [1, 2, 3] (array of user IDs - currently not used by backend)
  /// Note: The endpoint uses the authenticated user's ID from the token
  Future<List<BoutiqueModel>> getBoutiquesByUserIds(List<int> userIds) async {
    try {
      if (kDebugMode) {
        final baseUrl = _dio.options.baseUrl;
        print('📡 VmService.getBoutiquesByUserIds() → POST $baseUrl/Boutiques/getBoutiquesByUserIDs body=$userIds');
      }

      final response = await _dio.post(
        '/Boutiques/getBoutiquesByUserIDs',
        data: userIds,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = response.data;
        return jsonResponse
            .map((json) => BoutiqueModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load boutiques. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Request was cancelled');
      }
      if (e.response != null) {
        final message = e.response?.data['message'] as String?;
        throw Exception(message ?? 'An error occurred while fetching boutiques: ${e.message}');
      }
      throw Exception('An error occurred while fetching boutiques: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while fetching boutiques: $e');
    }
  }

  /// Get guideline assets
  /// GET /api/VmCompaign/guidelines/{guidelineId}/assets
  Future<List<VmGuidelineAsset>> getGuidelineAssets(int guidelineId) async {
    try {
      if (kDebugMode) {
        final baseUrl = _dio.options.baseUrl;
        print('📡 VmService.getGuidelineAssets() → GET $baseUrl/VmCompaign/guidelines/$guidelineId/assets');
      }

      final response = await _dio.get(
        '/VmCompaign/guidelines/$guidelineId/assets',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = response.data;
        return jsonResponse
            .map((json) => VmGuidelineAsset.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load guideline assets. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Request was cancelled');
      }
      if (e.response != null) {
        if (e.response?.statusCode == 404) {
          throw Exception('Guideline not found.');
        }
        final message = e.response?.data['message'] as String?;
        throw Exception(message ?? 'An error occurred while fetching guideline assets: ${e.message}');
      }
      throw Exception('An error occurred while fetching guideline assets: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while fetching guideline assets: $e');
    }
  }

  /// Download guideline asset
  /// GET /api/VmCompaign/assets/{assetId}/download
  /// Returns the path to the downloaded file
  /// Saves to app documents directory for persistence
  /// Checks if file already exists to avoid re-downloading
  Future<String> downloadGuidelineAsset(int assetId, String fileName, {String? storedFileName}) async {
    try {
      // Get app documents directory (persistent, doesn't require permissions)
      final appDocDir = await getApplicationDocumentsDirectory();
      final guidelinesDir = Directory('${appDocDir.path}/guidelines');
      
      // Create guidelines directory if it doesn't exist
      if (!await guidelinesDir.exists()) {
        await guidelinesDir.create(recursive: true);
      }

      // Use storedFileName if provided (unique), otherwise use fileName
      // Add assetId prefix to avoid conflicts between different assets with same name
      final uniqueFileName = storedFileName ?? '${assetId}_$fileName';
      final filePath = '${guidelinesDir.path}/$uniqueFileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // File already downloaded, update modified time for LRU cache
        // This ensures recently accessed files are kept longer
        try {
          await file.setLastModified(DateTime.now());
        } catch (e) {
          // Ignore if we can't update timestamp
          print('Could not update file timestamp: $e');
        }
        return filePath;
      }

      // Download the file
      final response = await _dio.get(
        '/VmCompaign/assets/$assetId/download',
        options: Options(
          responseType: ResponseType.bytes, // Important: get binary data
          followRedirects: false,
        ),
      );

      if (response.statusCode == 200) {
        // Save the file
        await file.writeAsBytes(response.data as List<int>);
        
        // Perform automatic cleanup after download (non-blocking)
        GuidelineCacheManager.performCleanup().catchError((e) {
          print('Cache cleanup error: $e');
        });
        
        return filePath;
      } else {
        throw Exception(
            'Failed to download asset. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Download was cancelled');
      }
      if (e.response != null) {
        if (e.response?.statusCode == 404) {
          throw Exception('Asset not found.');
        }
        final message = e.response?.data['message'] as String?;
        throw Exception(message ?? 'An error occurred while downloading asset: ${e.message}');
      }
      throw Exception('An error occurred while downloading asset: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while downloading asset: $e');
    }
  }
}
