import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_campaign_dto.dart';
import 'package:supervisormobile/services/DioService.dart';

String _normalizeVmPhotoUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  final baseWithoutApi = DioService.assetsBaseUrl;
  if (baseWithoutApi.isEmpty) return trimmed;

  final baseUri = Uri.tryParse(baseWithoutApi);
  if (baseUri == null) return trimmed;
  final relativePath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  final resolvedUrl = baseUri.resolve(relativePath).toString();
  return resolvedUrl;
}

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
    final rawUrl = json['url'] as String? ?? '';
    return VmExecutionPhotoDto(
      photoId: (json['photoId'] as num?)?.toInt() ?? 0,
      url: _normalizeVmPhotoUrl(rawUrl),
      fileName: json['fileName'] as String?,
    );
  }
}

class VmZoneExecutionDto {
  final int executionId;
  final int status;
  final String statusLabel;
  final bool isValidated;
  final List<VmExecutionPhotoDto> photos;
  final String? issues;

  const VmZoneExecutionDto({
    required this.executionId,
    required this.status,
    required this.statusLabel,
    required this.isValidated,
    required this.photos,
    this.issues,
  });

  factory VmZoneExecutionDto.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List<dynamic>? ?? <dynamic>[]);
    final statusLabel = _executionStatusToLabel(json['status']);
    final rawIssues = json['issues'] as String? ?? json['Issues'] as String?;
    return VmZoneExecutionDto(
      executionId: (json['executionId'] as num?)?.toInt() ?? 0,
      status: _executionStatusToInt(json['status']),
      statusLabel: statusLabel,
      isValidated: json['isValidated'] as bool? ?? false,
      photos: rawPhotos
          .map((p) => VmExecutionPhotoDto.fromJson(p as Map<String, dynamic>))
          .toList(),
      issues: (rawIssues != null && rawIssues.trim().isNotEmpty) ? rawIssues.trim() : null,
    );
  }

  String get normalizedStatusLabel => statusLabel.trim().toLowerCase();

  bool get isRejectedStatus =>
      normalizedStatusLabel == 'rejected' ||
      normalizedStatusLabel == 'disapproved';

  bool get isValidatedStatus =>
      isValidated ||
      normalizedStatusLabel == 'validated' ||
      normalizedStatusLabel == 'approved';
}

int _executionStatusToInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'planified':
      case 'planned':
        return 0;
      case 'inprogress':
      case 'in_progress':
        return 1;
      case 'completed':
        return 2;
      case 'validated':
      case 'approved':
        return 2;
      case 'rejected':
      case 'disapproved':
        return 3;
      case 'cancelled':
      case 'canceled':
        return 4;
      default:
        return 0;
    }
  }
  return 0;
}

String _executionStatusToLabel(dynamic value) {
  if (value is String) return value.trim().toLowerCase();
  if (value is num) {
    switch (value.toInt()) {
      case 2:
        return 'validated';
      case 3:
        return 'rejected';
      case 1:
        return 'in_progress';
      default:
        return 'not_started';
    }
  }
  return 'not_started';
}

class VmExecutionZoneDto {
  final int zoneId;
  final String zoneCode;
  final String zoneName;
  final int imagesCount;
  final String status;
  final bool isFinished;
  final List<VmZoneExecutionDto> executions;

  const VmExecutionZoneDto({
    required this.zoneId,
    required this.zoneCode,
    required this.zoneName,
    required this.imagesCount,
    required this.status,
    required this.isFinished,
    required this.executions,
  });

  factory VmExecutionZoneDto.fromJson(Map<String, dynamic> json) {
    final rawExecutions = _extractRawExecutions(json);
    final imagesCount = (json['imagesCount'] as num?)?.toInt() ?? 0;
    final rawStatus = (json['status'] as String?)?.trim().toLowerCase();
    final executions = rawExecutions
        .map((e) => VmZoneExecutionDto.fromJson(e as Map<String, dynamic>))
        .toList();
    final status = _deriveZoneStatus(
      rawStatus: rawStatus,
      imagesCount: imagesCount,
      executions: executions,
    );
    final isFinished = status == 'approved' || status == 'disapproved';
    return VmExecutionZoneDto(
      zoneId: (json['zoneId'] as num?)?.toInt() ?? 0,
      zoneCode: json['zoneCode'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
      imagesCount: imagesCount,
      status: status,
      isFinished: isFinished,
      executions: executions,
    );
  }

  List<VmExecutionPhotoDto> get allPhotos =>
      executions.expand((e) => e.photos).toList();

  /// Returns the rejection issue text from the latest rejected execution, if any.
  String? get rejectionIssues {
    VmZoneExecutionDto? latest;
    for (final e in executions) {
      if (latest == null || e.executionId >= latest.executionId) {
        latest = e;
      }
    }
    if (latest != null && latest.isRejectedStatus) return latest.issues;
    return null;
  }

  ZoneStatDto toZoneStatDto() => ZoneStatDto(
        zoneId: zoneId,
        zoneName: zoneName,
        zoneCode: zoneCode,
        imagesCount: imagesCount,
        status: status,
        isFinished: isFinished,
      );
}

List<dynamic> _extractRawExecutions(Map<String, dynamic> json) {
  final statusExecutions = json['statusExecutions'];
  if (statusExecutions is List<dynamic>) {
    return statusExecutions;
  }
  final siteExecutions = json['siteExecutions'];
  if (siteExecutions is List<dynamic>) {
    return siteExecutions;
  }
  final executions = json['executions'];
  if (executions is List<dynamic>) {
    return executions;
  }
  return <dynamic>[];
}

String _deriveZoneStatus({
  required String? rawStatus,
  required int imagesCount,
  required List<VmZoneExecutionDto> executions,
}) {
  VmZoneExecutionDto? latest;
  for (final execution in executions) {
    if (latest == null || execution.executionId >= latest.executionId) {
      latest = execution;
    }
  }

  if (latest != null) {
    if (latest.isRejectedStatus) return 'disapproved';
    if (latest.isValidatedStatus) return 'approved';
  }

  final hasPhotos = imagesCount > 0 || executions.any((e) => e.photos.isNotEmpty);
  if (hasPhotos) return 'submitted';

  if (rawStatus == 'approved' ||
      rawStatus == 'disapproved' ||
      rawStatus == 'submitted' ||
      rawStatus == 'not_started') {
    return rawStatus!;
  }
  return 'not_started';
}

enum SubmissionStatus {
  pending,
  processing,
  submitted,
  validated,
  rejected,
  unknown;

  static SubmissionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return SubmissionStatus.pending;
      case 'processing':
        return SubmissionStatus.processing;
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'validated':
        return SubmissionStatus.validated;
      case 'rejected':
        return SubmissionStatus.rejected;
      default:
        return SubmissionStatus.unknown;
    }
  }

  bool get isLocked =>
      this == SubmissionStatus.submitted || this == SubmissionStatus.validated;
}

class VmCampaignExecutionDto {
  final int campaignId;
  final int siteId;
  final List<VmExecutionZoneDto> zones;
  final SubmissionStatus submissionStatus;

  const VmCampaignExecutionDto({
    required this.campaignId,
    required this.siteId,
    required this.zones,
    this.submissionStatus = SubmissionStatus.unknown,
  });

  factory VmCampaignExecutionDto.fromJson(Map<String, dynamic> json) {
    final rawZones = (json['zones'] as List<dynamic>? ?? <dynamic>[]);
    return VmCampaignExecutionDto(
      campaignId: (json['compaignId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      zones: rawZones
          .map((z) => VmExecutionZoneDto.fromJson(z as Map<String, dynamic>))
          .toList(),
      submissionStatus: SubmissionStatus.fromString(json['submissionStatus'] as String?),
    );
  }

  List<ZoneStatDto> get zoneStats => zones.map((z) => z.toZoneStatDto()).toList();

  int get totalRemoteImages => zones.fold(0, (sum, z) => sum + z.imagesCount);
}
