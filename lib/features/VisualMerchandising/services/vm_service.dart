import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/services/DioService.dart';
import '../dtos/vm_campaign_dto.dart';
import '../dtos/vm_campaign_execution_dto.dart';
import '../dtos/vm_campaign_submit_dto.dart';
import '../dtos/vm_guideline_asset_dto.dart';
import '../../calendar/models/boutiqueModel.dart';
import 'guideline_cache_manager.dart';

/// Service for Visual Merchandising API calls
class VmService {
  static final Dio _dio = DioService.dio;
  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

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
        if (response.data is! List) {
          throw Exception('Invalid response format for campaigns by sites.');
        }
        final List<dynamic> jsonResponse = response.data as List<dynamic>;
        return jsonResponse
            .whereType<Map<String, dynamic>>()
            .map(VmCampaignDto.fromJson)
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

  Future<VmCampaignExecutionDto> getCampaignExecutionBySite({
    required int campaignId,
    required int siteId,
  }) async {
    try {
      if (campaignId <= 0 || siteId <= 0) {
        throw Exception('Campaign ID and site ID must be greater than zero.');
      }

      final response = await _dio.get(
        '/VmCompaign/$campaignId/sites/$siteId/executions',
      );

      if (response.statusCode == 200) {
        return VmCampaignExecutionDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to load campaign executions. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Request was cancelled');
      }
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String?
            : null;

        if (statusCode == 404) {
          throw Exception(
            message ?? 'Campaign not found or not linked to the provided site.',
          );
        }
        if (statusCode == 400) {
          throw Exception(
            message ?? 'Campaign ID and site ID must be greater than zero.',
          );
        }
        throw Exception(
          message ?? 'An error occurred while retrieving campaign executions.',
        );
      }
      throw Exception(
        'An error occurred while retrieving campaign executions: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'An error occurred while retrieving campaign executions: $e',
      );
    }
  }

  Future<VmCampaignSubmitResponseDto> submitCampaign({
    required int campaignId,
    required int siteId,
    required List<ZoneStatDto> zones,
    required Map<int, List<String>> localZonePhotos,
    required String platform,
    required String appVersion,
  }) async {
    try {
      if (campaignId <= 0 || siteId <= 0) {
        throw const VmSubmitApiException(
          message: 'campaignId/siteId invalides.',
        );
      }
      if (zones.isEmpty) {
        throw const VmSubmitApiException(
          message: 'Aucune zone a soumettre.',
        );
      }

      final zonePayload = <VmSubmitZoneDto>[];

      for (final zone in zones) {
        final paths = localZonePhotos[zone.zoneId] ?? const <String>[];
        if (paths.isEmpty) {
          continue;
        }
        final photos = <VmSubmitPhotoDto>[];
        for (final path in paths) {
          final file = File(path);
          if (!await file.exists()) {
            throw VmSubmitApiException(
              message: 'Photo introuvable pour la zone ${zone.zoneCode}.',
            );
          }
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            throw VmSubmitApiException(
              message: 'Photo vide detectee pour la zone ${zone.zoneCode}.',
            );
          }
          final fileName = file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final mimeType = lookupMimeType(path) ?? 'image/jpeg';
          if (!_allowedMimeTypes.contains(mimeType)) {
            throw VmSubmitApiException(
              message: 'Format image non supporte ($mimeType) pour ${zone.zoneCode}.',
            );
          }
          final encoded = base64Encode(bytes);
          if (encoded.isEmpty) {
            throw VmSubmitApiException(
              message: 'Base64 invalide pour la zone ${zone.zoneCode}.',
            );
          }
          try {
            base64Decode(encoded);
          } catch (_) {
            throw VmSubmitApiException(
              message: 'Base64 invalide pour la zone ${zone.zoneCode}.',
            );
          }
          photos.add(
            VmSubmitPhotoDto(
              fileName: fileName,
              mimeType: mimeType,
              contentBase64: encoded,
              capturedAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
        }

        if (photos.isEmpty) {
          throw VmSubmitApiException(
            message: 'Chaque zone doit contenir au moins une photo (${zone.zoneCode}).',
          );
        }
        zonePayload.add(
          VmSubmitZoneDto(
            zoneId: zone.zoneId,
            zoneCode: zone.zoneCode,
            photos: photos,
          ),
        );
      }

      if (zonePayload.isEmpty) {
        throw const VmSubmitApiException(
          message: 'Aucune zone valide a soumettre (photos requises).',
        );
      }

      final payload = VmCampaignSubmitRequestDto(
        campaignId: campaignId,
        siteId: siteId,
        submittedAt: DateTime.now().toUtc().toIso8601String(),
        zones: zonePayload,
        meta: <String, dynamic>{
          'appVersion': appVersion,
          'platform': platform,
        },
      );
      if (payload.campaignId != campaignId || payload.siteId != siteId) {
        throw const VmSubmitApiException(
          message: 'Mismatch entre URL et body (campaignId/siteId).',
        );
      }

      final response = await _dio.post(
        '/VmCompaign/$campaignId/sites/$siteId/submit',
        data: payload.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return VmCampaignSubmitResponseDto.fromJson(data);
        }
      }

      throw Exception(
        'Failed to submit campaign. Status code: ${response.statusCode}',
      );
    } on VmSubmitApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const VmSubmitApiException(
          message: 'La soumission a ete annulee.',
        );
      }
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final message = data['message'] as String?;
          final parsed = VmCampaignSubmitResponseDto.fromJson(data);
          throw VmSubmitApiException(
            message: message ?? parsed.message ?? 'Echec de soumission.',
            statusCode: statusCode,
            response: parsed,
          );
        }
        if (statusCode == 404) {
          throw const VmSubmitApiException(
            message: 'Campagne introuvable ou non liee au site.',
            statusCode: 404,
          );
        }
        if (statusCode == 500) {
          throw const VmSubmitApiException(
            message: 'Erreur serveur pendant la soumission.',
            statusCode: 500,
          );
        }
      }
      throw VmSubmitApiException(
        message: 'Erreur reseau pendant la soumission: ${e.message}',
      );
    } catch (e) {
      throw VmSubmitApiException(
        message: 'Erreur pendant la soumission: $e',
      );
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
