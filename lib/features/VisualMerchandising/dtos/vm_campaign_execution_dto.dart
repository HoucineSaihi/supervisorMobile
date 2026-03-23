import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';

class VmExecutionPhotoDto {
  final int photoId;
  final String url;
  final String? fileName;

  const VmExecutionPhotoDto({
    required this.photoId,
    required this.url,
    this.fileName,
  });

  factory VmExecutionPhotoDto.fromJson(Map<String, dynamic> json) {
    return VmExecutionPhotoDto(
      photoId: (json['photoId'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
      fileName: json['fileName'] as String?,
    );
  }
}

class VmZoneExecutionDto {
  final int executionId;
  final int status;
  final bool isValidated;
  final List<VmExecutionPhotoDto> photos;

  const VmZoneExecutionDto({
    required this.executionId,
    required this.status,
    required this.isValidated,
    required this.photos,
  });

  factory VmZoneExecutionDto.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List<dynamic>? ?? <dynamic>[]);
    return VmZoneExecutionDto(
      executionId: (json['executionId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      isValidated: json['isValidated'] as bool? ?? false,
      photos: rawPhotos
          .map((p) => VmExecutionPhotoDto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VmExecutionZoneDto {
  final int zoneId;
  final String zoneCode;
  final String zoneName;
  final int imagesCount;
  final bool isFinished;
  final List<VmZoneExecutionDto> executions;

  const VmExecutionZoneDto({
    required this.zoneId,
    required this.zoneCode,
    required this.zoneName,
    required this.imagesCount,
    required this.isFinished,
    required this.executions,
  });

  factory VmExecutionZoneDto.fromJson(Map<String, dynamic> json) {
    final rawExecutions = (json['executions'] as List<dynamic>? ?? <dynamic>[]);
    return VmExecutionZoneDto(
      zoneId: (json['zoneId'] as num?)?.toInt() ?? 0,
      zoneCode: json['zoneCode'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
      imagesCount: (json['imagesCount'] as num?)?.toInt() ?? 0,
      isFinished: json['isFinished'] as bool? ?? false,
      executions: rawExecutions
          .map((e) => VmZoneExecutionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<VmExecutionPhotoDto> get allPhotos =>
      executions.expand((e) => e.photos).toList();

  ZoneStatDto toZoneStatDto() => ZoneStatDto(
        zoneId: zoneId,
        zoneName: zoneName,
        zoneCode: zoneCode,
        imagesCount: imagesCount,
        isFinished: isFinished,
      );
}

class VmCampaignExecutionDto {
  final int campaignId;
  final int siteId;
  final List<VmExecutionZoneDto> zones;

  const VmCampaignExecutionDto({
    required this.campaignId,
    required this.siteId,
    required this.zones,
  });

  factory VmCampaignExecutionDto.fromJson(Map<String, dynamic> json) {
    final rawZones = (json['zones'] as List<dynamic>? ?? <dynamic>[]);
    return VmCampaignExecutionDto(
      campaignId: (json['compaignId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      zones: rawZones
          .map((z) => VmExecutionZoneDto.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  List<ZoneStatDto> get zoneStats => zones.map((z) => z.toZoneStatDto()).toList();

  int get totalRemoteImages => zones.fold(0, (sum, z) => sum + z.imagesCount);
}
