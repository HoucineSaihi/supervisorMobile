class VmSubmitPhotoDto {
  final String fileName;
  final String mimeType;
  final String contentBase64;
  final String capturedAt;

  const VmSubmitPhotoDto({
    required this.fileName,
    required this.mimeType,
    required this.contentBase64,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'mimeType': mimeType,
        'contentBase64': contentBase64,
        'capturedAt': capturedAt,
      };
}

/// Request body for POST .../sites/{siteId}/submit (finalize — no photos).
class VmFinalizeSiteExecutionRequestDto {
  final int campaignId;
  final int siteId;
  final bool confirmSubmission;
  final String submittedAt;
  final Map<String, dynamic> meta;

  const VmFinalizeSiteExecutionRequestDto({
    required this.campaignId,
    required this.siteId,
    this.confirmSubmission = true,
    required this.submittedAt,
    required this.meta,
  });

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'siteId': siteId,
        'confirmSubmission': confirmSubmission,
        'submittedAt': submittedAt,
        'meta': meta,
      };
}

class VmSubmitErrorDto {
  final int? zoneId;
  final String? code;

  const VmSubmitErrorDto({
    this.zoneId,
    this.code,
  });

  factory VmSubmitErrorDto.fromJson(Map<String, dynamic> json) {
    return VmSubmitErrorDto(
      zoneId: (json['zoneId'] as num?)?.toInt(),
      code: json['code'] as String?,
    );
  }
}

class VmSiteProgressDto {
  final int requiredZones;
  final int completedZones;
  final double progressPercent;
  final bool allZonesComplete;
  final List<int> incompleteZoneIds;

  const VmSiteProgressDto({
    required this.requiredZones,
    required this.completedZones,
    required this.progressPercent,
    required this.allZonesComplete,
    required this.incompleteZoneIds,
  });

  factory VmSiteProgressDto.fromJson(Map<String, dynamic> json) {
    final rawIds = (json['incompleteZoneIds'] as List<dynamic>?) ?? const <dynamic>[];
    return VmSiteProgressDto(
      requiredZones: (json['requiredZones'] as num?)?.toInt() ?? 0,
      completedZones: (json['completedZones'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
      allZonesComplete: json['allZonesComplete'] as bool? ?? false,
      incompleteZoneIds: rawIds.whereType<num>().map((e) => e.toInt()).toList(),
    );
  }
}

/// Response for both finalize (POST .../submit) and zone PUT.
class VmCampaignSubmitResponseDto {
  final bool success;
  final String? submissionId;
  final String? submissionStatus;
  final String? campaignStatus;
  final String? campaignReviewStatus;
  final int? processedZones;
  final int? processedPhotos;
  final String? message;
  final List<VmSubmitErrorDto> errors;
  final List<int> incompleteZoneIds;
  final VmSiteProgressDto? siteProgress;

  const VmCampaignSubmitResponseDto({
    required this.success,
    this.submissionId,
    this.submissionStatus,
    this.campaignStatus,
    this.campaignReviewStatus,
    this.processedZones,
    this.processedPhotos,
    this.message,
    this.errors = const <VmSubmitErrorDto>[],
    this.incompleteZoneIds = const <int>[],
    this.siteProgress,
  });

  factory VmCampaignSubmitResponseDto.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List<dynamic>?) ?? const <dynamic>[];
    final rawIds = (json['incompleteZoneIds'] as List<dynamic>?) ?? const <dynamic>[];
    final rawProgress = json['siteProgress'] as Map<String, dynamic>?;
    return VmCampaignSubmitResponseDto(
      success: json['success'] as bool? ?? false,
      submissionId: json['submissionId'] as String?,
      submissionStatus: json['submissionStatus'] as String?,
      campaignStatus: json['campaignStatus'] as String?,
      campaignReviewStatus: json['campaignReviewStatus'] as String?,
      processedZones: (json['processedZones'] as num?)?.toInt(),
      processedPhotos: (json['processedPhotos'] as num?)?.toInt(),
      message: json['message'] as String?,
      errors: rawErrors
          .whereType<Map<String, dynamic>>()
          .map(VmSubmitErrorDto.fromJson)
          .toList(),
      incompleteZoneIds: rawIds.whereType<num>().map((e) => e.toInt()).toList(),
      siteProgress: rawProgress != null ? VmSiteProgressDto.fromJson(rawProgress) : null,
    );
  }
}

class VmZoneSubmitResponseDto {
  final bool success;
  final String? submissionId;
  final String? submissionStatus;
  final String? campaignStatus;
  final String? campaignReviewStatus;
  final int? zoneId;
  final int? processedPhotos;
  final bool isLastZone;
  final String? message;
  final List<VmSubmitErrorDto> errors;

  const VmZoneSubmitResponseDto({
    required this.success,
    this.submissionId,
    this.submissionStatus,
    this.campaignStatus,
    this.campaignReviewStatus,
    this.zoneId,
    this.processedPhotos,
    this.isLastZone = false,
    this.message,
    this.errors = const <VmSubmitErrorDto>[],
  });

  factory VmZoneSubmitResponseDto.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List<dynamic>?) ?? const <dynamic>[];
    return VmZoneSubmitResponseDto(
      success: json['success'] as bool? ?? false,
      submissionId: json['submissionId'] as String?,
      submissionStatus: json['submissionStatus'] as String?,
      campaignStatus: json['campaignStatus'] as String?,
      campaignReviewStatus: json['campaignReviewStatus'] as String?,
      zoneId: (json['zoneId'] as num?)?.toInt(),
      processedPhotos: (json['processedPhotos'] as num?)?.toInt(),
      isLastZone: json['isLastZone'] as bool? ?? false,
      message: json['message'] as String?,
      errors: rawErrors
          .whereType<Map<String, dynamic>>()
          .map(VmSubmitErrorDto.fromJson)
          .toList(),
    );
  }
}

class VmSubmitApiException implements Exception {
  final String message;
  final int? statusCode;
  final VmCampaignSubmitResponseDto? response;

  const VmSubmitApiException({
    required this.message,
    this.statusCode,
    this.response,
  });

  @override
  String toString() => message;
}
