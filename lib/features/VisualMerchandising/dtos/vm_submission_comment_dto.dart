class VmSubmissionCommentDto {
  final int id;
  final int submissionId;
  final String submissionRef;
  final int authorUserId;
  final String authorName;
  final String authorInitials;
  final String authorRole;
  final String message;
  final DateTime createdAt;
  final bool isUnread;

  const VmSubmissionCommentDto({
    required this.id,
    required this.submissionId,
    required this.submissionRef,
    required this.authorUserId,
    required this.authorName,
    required this.authorInitials,
    required this.authorRole,
    required this.message,
    required this.createdAt,
    this.isUnread = false,
  });

  factory VmSubmissionCommentDto.fromJson(Map<String, dynamic> json) {
    return VmSubmissionCommentDto(
      id: (json['id'] as num).toInt(),
      submissionId: (json['submissionId'] as num).toInt(),
      submissionRef: json['submissionRef'] as String? ?? '',
      authorUserId: (json['authorUserId'] as num).toInt(),
      authorName: json['authorName'] as String? ?? '',
      authorInitials: json['authorInitials'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUnread: json['isUnread'] as bool? ?? false,
    );
  }
}
