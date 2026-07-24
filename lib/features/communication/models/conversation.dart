// Dart mirror of the backend ConversationDto family and the Angular
// conversation.model.ts.

enum ConversationType { oneToOne, group, channel, broadcast }

ConversationType _typeFrom(String? v) {
  switch (v) {
    case 'Group':
      return ConversationType.group;
    case 'Channel':
      return ConversationType.channel;
    case 'Broadcast':
      return ConversationType.broadcast;
    default:
      return ConversationType.oneToOne;
  }
}

class ConversationSummary {
  final int id;
  final ConversationType type;
  final String? title;
  final String? lastMessagePreview;
  final String? lastMessageSenderName;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final int memberCount;

  ConversationSummary({
    required this.id,
    required this.type,
    this.title,
    this.lastMessagePreview,
    this.lastMessageSenderName,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.memberCount = 0,
    this.isOnline = false,
    this.avatarUrl,
  });

  bool get isDirect => type == ConversationType.oneToOne;

  final bool isOnline;
  final String? avatarUrl;

  factory ConversationSummary.fromJson(Map<String, dynamic> j) {
    final last = j['lastMessage'] as Map<String, dynamic>?;
    return ConversationSummary(
      id: j['id'] ?? 0,
      type: _typeFrom(j['type']),
      title: j['displayName'] ?? j['title'],
      lastMessagePreview: last?['body'] ??
          (last != null ? _describeNonText(last) : null),
      lastMessageSenderName: last?['senderName'],
      lastMessageAt: j['lastMessageAt'] != null
          ? DateTime.tryParse(j['lastMessageAt'])?.toLocal()
          : null,
      unreadCount: j['unreadCount'] ?? 0,
      isMuted: j['isMuted'] ?? false,
      memberCount: j['memberCount'] ?? 0,
      isOnline: j['isOnline'] ?? false,
      avatarUrl: j['displayImg'],
    );
  }

  /// A short stand-in preview for a non-text last message (image/voice/file).
  static String _describeNonText(Map<String, dynamic> last) {
    switch (last['type']) {
      case 'Image':
        return '📷 Photo';
      case 'Voice':
        return '🎤 Voice message';
      case 'File':
        return '📎 File';
      default:
        return '';
    }
  }

  ConversationSummary copyWith({int? unreadCount}) => ConversationSummary(
        id: id,
        type: type,
        title: title,
        lastMessagePreview: lastMessagePreview,
        lastMessageSenderName: lastMessageSenderName,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted,
        memberCount: memberCount,
        isOnline: isOnline,
        avatarUrl: avatarUrl,
      );
}

class ConversationListResponse {
  final List<ConversationSummary> conversations;
  final int page;
  final bool hasMore;

  ConversationListResponse({
    required this.conversations,
    required this.page,
    required this.hasMore,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> j) => ConversationListResponse(
        conversations: (j['conversations'] as List<dynamic>? ?? [])
            .map((c) => ConversationSummary.fromJson(c))
            .toList(),
        page: j['page'] ?? 1,
        hasMore: j['hasMore'] ?? false,
      );
}

class ConversationMember {
  final int caisseId;
  final String? name;
  final String role;

  ConversationMember({required this.caisseId, this.name, this.role = 'Member'});

  factory ConversationMember.fromJson(Map<String, dynamic> j) => ConversationMember(
        caisseId: j['caisseId'] ?? 0,
        name: j['name'],
        role: j['role'] ?? 'Member',
      );
}

class ConversationDetail {
  final int id;
  final ConversationType type;
  final String? title;
  final List<ConversationMember> members;

  ConversationDetail({
    required this.id,
    required this.type,
    this.title,
    this.members = const [],
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> j) => ConversationDetail(
        id: j['id'] ?? 0,
        type: _typeFrom(j['type']),
        title: j['displayName'] ?? j['title'],
        members: (j['members'] as List<dynamic>? ?? [])
            .map((m) => ConversationMember.fromJson(m))
            .toList(),
      );
}

class MemberPresence {
  final int caisseId;
  final bool isOnline;

  MemberPresence({required this.caisseId, required this.isOnline});

  factory MemberPresence.fromJson(Map<String, dynamic> j) => MemberPresence(
        caisseId: j['caisseId'] ?? 0,
        isOnline: j['isOnline'] ?? false,
      );
}
