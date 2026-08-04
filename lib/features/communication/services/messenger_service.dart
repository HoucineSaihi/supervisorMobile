import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

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

  // ── Conversation-level actions ────────────────────────
  //
  // Note these are about the *conversation*, not a message. The message-level
  // pinMessage/unpinMessage further down are a separate feature that happens to share
  // the word "pin" — the backend models them on different tables entirely.

  /// Pins/unpins the conversation in this user's own list. Personal, not shared.
  /// `PATCH /Conversations/{id}/pin?pinned=<bool>` — the flag is a query param.
  Future<void> setConversationPinned(int conversationId, bool pinned) async {
    await _dio.patch(
      '$_base/$conversationId/pin',
      queryParameters: {'pinned': pinned},
    );
  }

  /// Mutes until [mutedUntil], or unmutes when it is null.
  ///
  /// `PATCH /Conversations/{id}/mute?mutedUntil=<iso8601>`. The server binds this
  /// `[FromQuery] DateTime?`, and omitting the parameter entirely is what clears the
  /// mute — so the key is conditionally spread rather than sent as a null.
  Future<void> setConversationMuted(int conversationId, DateTime? mutedUntil) async {
    await _dio.patch(
      '$_base/$conversationId/mute',
      queryParameters: {
        if (mutedUntil != null) 'mutedUntil': mutedUntil.toUtc().toIso8601String(),
      },
    );
  }

  /// Leaves a group/channel. Past messages stay attributed to the user.
  Future<void> leaveConversation(int conversationId) async {
    await _dio.post('$_base/$conversationId/leave');
  }

  /// Creates, or returns the existing, 1:1 thread with [recipientCaisseId].
  Future<ConversationDetail> createDirectConversation(int recipientCaisseId) async {
    final res = await _dio.post('$_base/direct', data: {
      'recipientCaisseId': recipientCaisseId,
    });
    return ConversationDetail.fromJson(res.data);
  }

  Future<ConversationDetail> createGroupConversation(
      String title, List<int> memberCaisseIds) async {
    final res = await _dio.post('$_base/groups', data: {
      'title': title,
      'memberCaisseIds': memberCaisseIds,
    });
    return ConversationDetail.fromJson(res.data);
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

  /// Messages pinned in this conversation, newest pin first.
  Future<List<PinnedMessage>> getPinnedMessages(int conversationId) async {
    final res = await _dio.get('$_base/$conversationId/pins');
    return (res.data as List<dynamic>).map((p) => PinnedMessage.fromJson(p)).toList();
  }

  /// Full-history search within one conversation, newest hit first. Server requires at
  /// least two characters and caps [limit] at 100.
  Future<MessagePage> searchMessages(int conversationId, String query, {int limit = 40}) async {
    final res = await _dio.get(
      '$_base/$conversationId/messages/search',
      queryParameters: {'q': query, 'limit': limit},
    );
    return MessagePage.fromJson(res.data);
  }

  /// Promotes a message into a tracked incident and returns the new incident's status.
  ///
  /// The server infers the store from the conversation's scope when [boutiqueId] is
  /// omitted, and is idempotent — converting the same message twice returns the
  /// original incident rather than creating a duplicate.
  Future<IncidentStatusSummary> convertMessageToIncident(
    int conversationId,
    int messageId, {
    String? description,
    int? boutiqueId,
  }) async {
    final res = await _dio.post(
      '$_base/$conversationId/messages/$messageId/convert-to-incident',
      data: {
        if (description != null) 'description': description,
        if (boutiqueId != null) 'boutiqueId': boutiqueId,
      },
    );
    return IncidentStatusSummary.fromJson(res.data);
  }

  /// Current status of an incident, for the in-thread card. Read on load, not pushed.
  Future<IncidentStatusSummary> getIncidentStatusSummary(int incidentId) async {
    final res = await _dio.get('$_base/incidents/$incidentId/status-summary');
    return IncidentStatusSummary.fromJson(res.data);
  }

  /// Everything shared in the conversation, optionally narrowed to one kind — backs
  /// the info screen's media and files tabs.
  Future<List<MessageAttachment>> getAttachments(
    int conversationId, {
    AttachmentKind? kind,
    int page = 1,
    int pageSize = 40,
  }) async {
    final res = await _dio.get(
      '$_base/$conversationId/attachments',
      queryParameters: {
        if (kind != null) 'kind': _attachmentKindToJson(kind),
        'page': page,
        'pageSize': pageSize,
      },
    );
    final data = res.data;
    // The endpoint returns a paged envelope; tolerate a bare list too.
    final items = data is List ? data : (data['attachments'] as List<dynamic>? ?? []);
    return items.map((a) => MessageAttachment.fromJson(a)).toList();
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

  /// Who has and hasn't read one of my messages. Server restricts this to the
  /// sender, so calling it for someone else's message returns 403.
  Future<MessageReceipts> getReceipts(int conversationId, int messageId) async {
    final res = await _dio.get('$_base/$conversationId/messages/$messageId/receipts');
    return MessageReceipts.fromJson(res.data);
  }

  Future<List<MemberPresence>> getPresence(int conversationId) async {
    final res = await _dio.get('$_base/$conversationId/presence');
    return (res.data as List<dynamic>).map((p) => MemberPresence.fromJson(p)).toList();
  }

  /// Uploads and stages a file, returning its attachment id for binding to a send.
  ///
  /// The content type is set explicitly from the file extension: the server validates
  /// it against a per-kind allow-list (AttachmentService.VoiceTypes/ImageTypes), and
  /// Dio would otherwise default to application/octet-stream — which that check
  /// rejects, failing every upload with a 400.
  Future<MessageAttachment> uploadAttachment(
    int conversationId,
    String filePath,
    String fileName,
    AttachmentKind kind, {
    int? durationSeconds,
    int? width,
    int? height,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(contentTypeFor(fileName, kind)),
      ),
      'kind': _attachmentKindToJson(kind),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    final res = await _dio.post('$_base/$conversationId/attachments', data: form);
    return MessageAttachment.fromJson(res.data);
  }

  /// Best-effort MIME type from a file name, constrained to what the server accepts
  /// for [kind]. Falls back to a safe per-kind default rather than octet-stream.
  static String contentTypeFor(String fileName, AttachmentKind kind) {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
        : '';
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.m4a':
      case '.mp4':
      case '.aac':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.webm':
        return 'audio/webm';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';
      case '.zip':
        return 'application/zip';
      default:
        switch (kind) {
          case AttachmentKind.image:
            return 'image/jpeg';
          case AttachmentKind.voice:
            return 'audio/mp4';
          case AttachmentKind.file:
            return 'application/octet-stream';
        }
    }
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
