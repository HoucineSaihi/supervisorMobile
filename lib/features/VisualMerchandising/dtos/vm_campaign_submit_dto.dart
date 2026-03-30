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

class VmSubmitZoneDto {
  final int zoneId;
  final String zoneCode;
  final List<VmSubmitPhotoDto> photos;

  const VmSubmitZoneDto({
    required this.zoneId,
    required this.zoneCode,
    required this.photos,
  });

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'zoneCode': zoneCode,
        'photos': photos.map((photo) => photo.toJson()).toList(),
      };
}

class VmCampaignSubmitRequestDto {
  final int campaignId;
  final int siteId;
  final String submittedAt;
  final List<VmSubmitZoneDto> zones;
  final Map<String, dynamic> meta;

  const VmCampaignSubmitRequestDto({
    required this.campaignId,
    required this.siteId,
    required this.submittedAt,
    required this.zones,
    required this.meta,
  });

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'siteId': siteId,
        'submittedAt': submittedAt,
        'zones': zones.map((zone) => zone.toJson()).toList(),
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

class VmCampaignSubmitResponseDto {
  final bool success;
  final String? submissionId;
  final String? campaignStatus;
  final int? processedZones;
  final int? processedPhotos;
  final String? message;
  final List<VmSubmitErrorDto> errors;

  const VmCampaignSubmitResponseDto({
    required this.success,
    this.submissionId,
    this.campaignStatus,
    this.processedZones,
    this.processedPhotos,
    this.message,
    this.errors = const <VmSubmitErrorDto>[],
  });

  factory VmCampaignSubmitResponseDto.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List<dynamic>?) ?? const <dynamic>[];
    return VmCampaignSubmitResponseDto(
      success: json['success'] as bool? ?? false,
      submissionId: json['submissionId'] as String?,
      campaignStatus: json['campaignStatus'] as String?,
      processedZones: (json['processedZones'] as num?)?.toInt(),
      processedPhotos: (json['processedPhotos'] as num?)?.toInt(),
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
