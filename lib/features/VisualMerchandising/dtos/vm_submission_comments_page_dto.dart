import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_submission_comment_dto.dart';

/// Response of GET .../submission-comments (marks thread as read on success).
class VmSubmissionCommentsPageDto {
  final List<VmSubmissionCommentDto> comments;
  final int totalCount;
  /// Unread count **before** this GET marks the thread as read.
  final int unreadCount;

  const VmSubmissionCommentsPageDto({
    required this.comments,
    required this.totalCount,
    required this.unreadCount,
  });

  factory VmSubmissionCommentsPageDto.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'] as List<dynamic>? ?? <dynamic>[];
    return VmSubmissionCommentsPageDto(
      comments: rawComments
          .whereType<Map<String, dynamic>>()
          .map(VmSubmissionCommentDto.fromJson)
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? rawComments.length,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Legacy: API used to return a bare array of comments.
  factory VmSubmissionCommentsPageDto.fromLegacyList(List<dynamic> list) {
    final comments = list
        .whereType<Map<String, dynamic>>()
        .map(VmSubmissionCommentDto.fromJson)
        .toList();
    return VmSubmissionCommentsPageDto(
      comments: comments,
      totalCount: comments.length,
      unreadCount: 0,
    );
  }
}

/// Response of GET /api/VmCompaign/comments/unread-summary
class VmCommentsUnreadSummaryDto {
  final int totalUnreadCount;

  const VmCommentsUnreadSummaryDto({required this.totalUnreadCount});

  factory VmCommentsUnreadSummaryDto.fromJson(Map<String, dynamic> json) {
    return VmCommentsUnreadSummaryDto(
      totalUnreadCount: (json['totalUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
