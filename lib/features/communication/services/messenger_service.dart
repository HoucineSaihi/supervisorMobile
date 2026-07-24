import 'package:dio/dio.dart';

import '../../../services/DioService.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// REST client for the messenger — the write path. Mirrors the Angular
/// ConversationService and the backend ConversationsController one-to-one.
/// SignalR only ever pushes what these calls produce.
class MessengerService {
  static final Dio _dio = DioService.dio;
  static const String _base = '/Conversations';

  /// API origin without the `/api` suffix, for building the hub URL and for
  /// resolving attachment content routes.
  static String get apiRoot => '${DioService.assetsBaseUrl}/api/';

  Future<ConversationListResponse> getConversations({int page = 1, int pageSize = 30}) async {
    final res = await _dio.get('$_base?page=$page&pageSize=$pageSize');
    return ConversationListResponse.fromJson(res.data);
  }

  Future<ConversationDetail> getConversation(int id) async {
    final res = await _dio.get('$_base/$id');
    return ConversationDetail.fromJson(res.data);
  }

  Future<MessagePage> getMessages(
    int id, {
    int? beforeSequence,
    int? afterSequence,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{'pageSize': pageSize};
    if (beforeSequence != null) params['beforeSequence'] = beforeSequence;
    if (afterSequence != null) params['afterSequence'] = afterSequence;
    final res = await _dio.get('$_base/$id/messages', queryParameters: params);
    return MessagePage.fromJson(res.data);
  }

  Future<Message> getMessage(int conversationId, int messageId) async {
    final res = await _dio.get('$_base/$conversationId/messages/$messageId');
    return Message.fromJson(res.data);
  }

  Future<Message> sendMessage(
    int conversationId, {
    required String clientMessageId,
    String? body,
    MessagePriority priority = MessagePriority.normal,
    int? replyToMessageId,
    List<int>? attachmentIds,
  }) async {
    final res = await _dio.post('$_base/$conversationId/messages', data: {
      'clientMessageId': clientMessageId,
      'type': 'Text',
      'body': body,
      'priority': priorityToJson(priority),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (attachmentIds != null && attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
    });
    return Message.fromJson(res.data);
  }

  Future<void> markRead(int conversationId, int lastReadMessageId, int lastReadSequence) async {
    await _dio.post('$_base/$conversationId/read', data: {
      'lastReadMessageId': lastReadMessageId,
      'lastReadSequence': lastReadSequence,
    });
  }

  Future<List<ReactionSummary>> toggleReaction(
      int conversationId, int messageId, String emoji) async {
    final res = await _dio.post(
      '$_base/$conversationId/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return (res.data as List<dynamic>).map((r) => ReactionSummary.fromJson(r)).toList();
  }

  Future<List<String>> getAllowedReactions() async {
    final res = await _dio.get('$_base/reactions/allowed');
    return (res.data as List<dynamic>).map((e) => e.toString()).toList();
  }

  // ── Phase B interactions ──────────────────────────────

  Future<List<String>> getAllowedReactionsEmoji() => getAllowedReactions();

  Future<List<ReactionSummary>> toggleReactionOn(
          int conversationId, int messageId, String emoji) =>
      toggleReaction(conversationId, messageId, emoji);

  Future<Message> editMessage(int conversationId, int messageId, String body) async {
    final res = await _dio.patch(
      '$_base/$conversationId/messages/$messageId',
      data: {'body': body},
    );
    return Message.fromJson(res.data);
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _dio.delete('$_base/$conversationId/messages/$messageId');
  }

  Future<void> pinMessage(int conversationId, int messageId) async {
    await _dio.post('$_base/$conversationId/messages/$messageId/pin');
  }

  Future<void> unpinMessage(int conversationId, int messageId) async {
    await _dio.delete('$_base/$conversationId/messages/$messageId/pin');
  }

  // ── Phase C mentions ──────────────────────────────────

  /// Autocomplete candidates for the composer's @-menu.
  Future<List<MentionSuggestion>> suggestMentions(
    int conversationId,
    String query, {
    String? entityType,
    int limit = 8,
  }) async {
    final res = await _dio.get(
      '$_base/$conversationId/mentions/suggest',
      queryParameters: {
        'q': query,
        if (entityType != null) 'entityType': entityType,
        'limit': limit,
      },
    );
    final list = (res.data['suggestions'] as List<dynamic>? ?? []);
    return list.map((s) => MentionSuggestion.fromJson(s)).toList();
  }

  Future<List<MemberPresence>> getPresence(int conversationId) async {
    final res = await _dio.get('$_base/$conversationId/presence');
    return (res.data as List<dynamic>).map((p) => MemberPresence.fromJson(p)).toList();
  }

  /// Uploads and stages a file, returning its attachment id for binding to a send.
  Future<MessageAttachment> uploadAttachment(
    int conversationId,
    String filePath,
    String fileName,
    AttachmentKind kind, {
    int? durationSeconds,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'kind': _attachmentKindToJson(kind),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });
    final res = await _dio.post('$_base/$conversationId/attachments', data: form);
    return MessageAttachment.fromJson(res.data);
  }

  /// Fetches attachment bytes through the authorized route (E-R2). Dio applies
  /// the auth interceptor, so — unlike a bare image URL — this carries the token.
  Future<List<int>> downloadAttachment(String relativeUrl) async {
    final res = await _dio.get<List<int>>(
      '${DioService.assetsBaseUrl}/$relativeUrl',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  // ── Notifications ─────────────────────────────────────

  /// The recipient's current unread notification total. Used to prime the badge on
  /// startup and as a backstop after any realtime gap — a missed [Notification] push
  /// then self-heals on the next resync instead of leaving the badge permanently stale.
  Future<int> getUnreadNotificationCount() async {
    final res = await _dio.get('/Notifications/unread-count');
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  static String _attachmentKindToJson(AttachmentKind k) {
    switch (k) {
      case AttachmentKind.voice:
        return 'Voice';
      case AttachmentKind.file:
        return 'File';
      case AttachmentKind.image:
        return 'Image';
    }
  }
}
