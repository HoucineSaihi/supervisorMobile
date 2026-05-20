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
import '../dtos/vm_submission_comment_dto.dart';
import '../dtos/vm_submission_comments_page_dto.dart';
import '../../calendar/models/boutiqueModel.dart';
import 'guideline_cache_manager.dart';

class VmCampaignsPaginationDto {
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isFirstPage;
  final bool isLastPage;
  final int currentPageSize;
  final int remainingItems;
  final int? nextPageNumber;
  final int? previousPageNumber;

  const VmCampaignsPaginationDto({
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isFirstPage,
    required this.isLastPage,
    required this.currentPageSize,
    required this.remainingItems,
    required this.nextPageNumber,
    required this.previousPageNumber,
  });

  factory VmCampaignsPaginationDto.fromJson(Map<String, dynamic> json) {
    final nextPage = (json['nextPageNumber'] as num?)?.toInt();
    final previousPage = (json['previousPageNumber'] as num?)?.toInt();
    return VmCampaignsPaginationDto(
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      isFirstPage: json['isFirstPage'] as bool? ?? true,
      isLastPage: json['isLastPage'] as bool? ?? true,
      currentPageSize: (json['currentPageSize'] as num?)?.toInt() ?? 0,
      remainingItems: (json['remainingItems'] as num?)?.toInt() ?? 0,
      nextPageNumber: nextPage != null && nextPage > 0 ? nextPage : null,
      previousPageNumber:
          previousPage != null && previousPage > 0 ? previousPage : null,
    );
  }
}

class VmCampaignsKpisDto {
  final int totalUnreadComments;

  const VmCampaignsKpisDto({required this.totalUnreadComments});

  factory VmCampaignsKpisDto.fromJson(Map<String, dynamic> json) {
    return VmCampaignsKpisDto(
      totalUnreadComments: (json['totalUnreadComments'] as num?)?.toInt() ?? 0,
    );
  }
}

class VmCampaignsPageDto {
  final List<VmCampaignDto> data;
  final VmCampaignsPaginationDto pagination;
  final VmCampaignsKpisDto? kpis;

  const VmCampaignsPageDto({
    required this.data,
    required this.pagination,
    this.kpis,
  });
}

/// Service for Visual Merchandising API calls
class VmService {
  static final Dio _dio = DioService.dio;
  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Get campaigns by site IDs (paginated)
  /// POST /api/VmCompaign/by-sites?pageNumber=1
  /// Request body: [1, 2, 3] (array of site IDs)
  Future<VmCampaignsPageDto> getCampaignsBySites(
    List<int> siteIds, {
    int pageNumber = 1,
  }) async {
    try {
      if (siteIds.isEmpty) {
        throw Exception('At least one site ID is required.');
      }
      if (pageNumber <= 0) {
        throw Exception('pageNumber must be greater than zero.');
      }

      if (kDebugMode) {
        final baseUrl = _dio.options.baseUrl;
        print(
          '📡 VmService.getCampaignsBySites() → POST '
          '$baseUrl/VmCompaign/by-sites?pageNumber=$pageNumber body=$siteIds',
        );
      }

      final response = await _dio.post(
        '/VmCompaign/by-sites',
        queryParameters: {'pageNumber': pageNumber},
        data: siteIds,
      );

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('Invalid response format for campaigns by sites.');
        }
        final jsonResponse = response.data as Map<String, dynamic>;
        final rawData = (jsonResponse['data'] as List<dynamic>? ?? <dynamic>[]);
        final rawPagination =
            (jsonResponse['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{});

        final campaigns = rawData
            .whereType<Map<String, dynamic>>()
            .map(VmCampaignDto.fromJson)
            .toList();
        final pagination = VmCampaignsPaginationDto.fromJson(rawPagination);
        final rawKpis = jsonResponse['kpis'];
        final kpis = rawKpis is Map<String, dynamic>
            ? VmCampaignsKpisDto.fromJson(rawKpis)
            : null;

        return VmCampaignsPageDto(
          data: campaigns,
          pagination: pagination,
          kpis: kpis,
        );
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

  /// POST /api/VmCompaign/{campaignId}/sites/{siteId}/submit
  /// Declares execution complete for a site. Zones and photos must already be
  /// saved via individual zone PUT calls before calling this.
  Future<VmCampaignSubmitResponseDto> finalizeSiteExecution({
    required int campaignId,
    required int siteId,
    required String platform,
    required String appVersion,
  }) async {
    try {
      if (campaignId <= 0 || siteId <= 0) {
        throw const VmSubmitApiException(
          message: 'campaignId/siteId invalides.',
        );
      }

      final payload = VmFinalizeSiteExecutionRequestDto(
        campaignId: campaignId,
        siteId: siteId,
        submittedAt: DateTime.now().toUtc().toIso8601String(),
        meta: <String, dynamic>{
          'appVersion': appVersion,
          'platform': platform,
        },
      );

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
        'Failed to finalize campaign. Status code: ${response.statusCode}',
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
          final parsed = VmCampaignSubmitResponseDto.fromJson(data);
          throw VmSubmitApiException(
            message: data['message'] as String? ?? parsed.message ?? 'Echec de soumission.',
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

  /// GET /api/VmCompaign/comments/unread-summary
  Future<VmCommentsUnreadSummaryDto> getCommentsUnreadSummary() async {
    try {
      final response = await _dio.get('/VmCompaign/comments/unread-summary');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return VmCommentsUnreadSummaryDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to load unread summary. Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) throw Exception('Request cancelled');
      final message = (e.response?.data is Map<String, dynamic>)
          ? e.response!.data['message'] as String?
          : null;
      throw Exception(message ?? 'Failed to load unread summary: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load unread summary: $e');
    }
  }

  /// GET /api/VmCompaign/{campaignId}/sites/{siteId}/submission-comments
  /// Marks the thread as read for the current user (side effect on success).
  Future<VmSubmissionCommentsPageDto> getSubmissionComments({
    required int campaignId,
    required int siteId,
  }) async {
    try {
      final response = await _dio.get(
        '/VmCompaign/$campaignId/sites/$siteId/submission-comments',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return VmSubmissionCommentsPageDto.fromJson(data);
        }
        if (data is List) {
          return VmSubmissionCommentsPageDto.fromLegacyList(data);
        }
        return const VmSubmissionCommentsPageDto(
          comments: [],
          totalCount: 0,
          unreadCount: 0,
        );
      }
      throw Exception('Failed to load comments. Status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) throw Exception('Request cancelled');
      final message = (e.response?.data is Map<String, dynamic>)
          ? e.response!.data['message'] as String?
          : null;
      throw Exception(message ?? 'Failed to load comments: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /// POST /api/VmCompaign/{campaignId}/sites/{siteId}/submission-comments
  Future<VmSubmissionCommentDto> postSubmissionComment({
    required int campaignId,
    required int siteId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/VmCompaign/$campaignId/sites/$siteId/submission-comments',
        data: {'message': message},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return VmSubmissionCommentDto.fromJson(data);
        }
      }
      throw Exception('Failed to post comment. Status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) throw Exception('Request cancelled');
      final message = (e.response?.data is Map<String, dynamic>)
          ? e.response!.data['message'] as String?
          : null;
      throw Exception(message ?? 'Failed to post comment: ${e.message}');
    } catch (e) {
      throw Exception('Failed to post comment: $e');
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

  /// Submit a single zone's execution using delta mode
  /// Keeps selected existing photos and adds new ones
  /// PUT /api/VmCompaign/{campaignId}/sites/{siteId}/zones/{zoneId}/execution
  Future<VmZoneSubmitResponseDto> submitZoneExecution({
    required int campaignId,
    required int siteId,
    required int zoneId,
    required String zoneCode,
    required List<int> keepPhotoIds,
    required List<String> newPhotoPaths,
    required String platform,
    required String appVersion,
  }) async {
    try {
      if (campaignId <= 0 || siteId <= 0 || zoneId <= 0) {
        throw const VmSubmitApiException(
          message: 'campaignId/siteId/zoneId invalides.',
        );
      }
      if (keepPhotoIds.isEmpty && newPhotoPaths.isEmpty) {
        throw VmSubmitApiException(
          message: 'Au moins une photo est requise pour la zone $zoneCode.',
        );
      }

      final newPhotos = <VmSubmitPhotoDto>[];
      for (final path in newPhotoPaths) {
        final file = File(path);
        if (!await file.exists()) {
          throw VmSubmitApiException(
            message: 'Photo introuvable pour la zone $zoneCode.',
          );
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw VmSubmitApiException(
            message: 'Photo vide detectee pour la zone $zoneCode.',
          );
        }
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final mimeType = lookupMimeType(path) ?? 'image/jpeg';
        if (!_allowedMimeTypes.contains(mimeType)) {
          throw VmSubmitApiException(
            message: 'Format image non supporte ($mimeType) pour $zoneCode.',
          );
        }
        final encoded = base64Encode(bytes);
        if (encoded.isEmpty) {
          throw VmSubmitApiException(
            message: 'Base64 invalide pour la zone $zoneCode.',
          );
        }
        try {
          base64Decode(encoded);
        } catch (_) {
          throw VmSubmitApiException(
            message: 'Base64 invalide pour la zone $zoneCode.',
          );
        }
        newPhotos.add(
          VmSubmitPhotoDto(
            fileName: fileName,
            mimeType: mimeType,
            contentBase64: encoded,
            capturedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      }

      final payload = <String, dynamic>{
        'keepPhotoIds': keepPhotoIds,
        'newPhotos': newPhotos.map((p) => p.toJson()).toList(),
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
        'meta': <String, dynamic>{
          'appVersion': appVersion,
          'platform': platform,
        },
      };

      final response = await _dio.put(
        '/VmCompaign/$campaignId/sites/$siteId/zones/$zoneId/execution',
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return VmZoneSubmitResponseDto.fromJson(data);
        }
      }

      throw Exception(
        'Failed to submit zone. Status code: ${response.statusCode}',
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
          throw VmSubmitApiException(
            message: message ?? 'Echec de soumission de zone.',
            statusCode: statusCode,
          );
        }
        if (statusCode == 404) {
          throw const VmSubmitApiException(
            message: 'Campagne, site ou zone introuvable.',
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
          return 0;
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
