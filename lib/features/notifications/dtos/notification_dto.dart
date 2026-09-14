// ─────────────────────────────────────────────────────────
// notification_dto.dart
// Traduit la réponse JSON du backend en objets Dart.
// Endpoint : GET /api/Notification
// ─────────────────────────────────────────────────────────

enum NotificationKind {
  executionSubmissionCompleted,
  executionRejected,
  unknown,
}

NotificationKind notificationKindFromString(String value) {
  switch (value) {
    case 'ExecutionSubmissionCompleted':
      return NotificationKind.executionSubmissionCompleted;
    case 'ExecutionRejected':
      return NotificationKind.executionRejected;
    default:
      return NotificationKind.unknown;
  }
}

class NotificationItemDto {
  final int id;
  final NotificationKind type;
  final String title;
  final String body;
  final int? campaignId;
  final int? siteId;
  final int? executionId;
  final int? submissionId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItemDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.campaignId,
    this.siteId,
    this.executionId,
    this.submissionId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: json['id'] as int,
      type: notificationKindFromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      campaignId: json['campaignId'] as int?,
      siteId: json['siteId'] as int?,
      executionId: json['executionId'] as int?,
      submissionId: json['submissionId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
