// Dart mirror of the backend MessageDto (DTO/MessengerDtos/MessageDtos.cs) and the
// Angular message.model.ts. Field names follow the JSON the API emits (camelCase).

enum MessageType { text, image, voice, file, system, incidentCard }

enum MessagePriority { normal, urgent, important, critical }

enum MessageReceiptState { sent, delivered, read, acknowledged }

enum AttachmentKind { image, file, voice }

/// Local-only status while a send is in flight or queued offline — never comes
/// from the server. Mirrors the web PendingMessage pattern.
enum PendingStatus { sending, queued, failed }

MessageType _messageTypeFrom(String? v) {
  switch (v) {
    case 'Image':
      return MessageType.image;
    case 'Voice':
      return MessageType.voice;
    case 'File':
      return MessageType.file;
    case 'System':
      return MessageType.system;
    case 'IncidentCard':
      return MessageType.incidentCard;
    default:
      return MessageType.text;
  }
}

String messageTypeToJson(MessageType t) {
  switch (t) {
    case MessageType.image:
      return 'Image';
    case MessageType.voice:
      return 'Voice';
    case MessageType.file:
      return 'File';
    case MessageType.system:
      return 'System';
    case MessageType.incidentCard:
      return 'IncidentCard';
    case MessageType.text:
      return 'Text';
  }
}

MessagePriority _priorityFrom(String? v) {
  switch (v) {
    case 'Urgent':
      return MessagePriority.urgent;
    case 'Important':
      return MessagePriority.important;
    case 'Critical':
      return MessagePriority.critical;
    default:
      return MessagePriority.normal;
  }
}

String priorityToJson(MessagePriority p) {
  switch (p) {
    case MessagePriority.urgent:
      return 'Urgent';
    case MessagePriority.important:
      return 'Important';
    case MessagePriority.critical:
      return 'Critical';
    case MessagePriority.normal:
      return 'Normal';
  }
}

MessageReceiptState _receiptFrom(String? v) {
  switch (v) {
    case 'Delivered':
      return MessageReceiptState.delivered;
    case 'Read':
      return MessageReceiptState.read;
    case 'Acknowledged':
      return MessageReceiptState.acknowledged;
    default:
      return MessageReceiptState.sent;
  }
}

AttachmentKind _attachmentKindFrom(String? v) {
  switch (v) {
    case 'Voice':
      return AttachmentKind.voice;
    case 'File':
      return AttachmentKind.file;
    default:
      return AttachmentKind.image;
  }
}

/// A candidate in the composer's @-autocomplete.
class MentionSuggestion {
  final String entityType;
  final int entityId;
  final String label;
  final String? context;

  /// Token to insert into the body, e.g. "@[Incident:521]".
  final String token;

  MentionSuggestion({
    required this.entityType,
    required this.entityId,
    required this.label,
    this.context,
    required this.token,
  });

  factory MentionSuggestion.fromJson(Map<String, dynamic> j) => MentionSuggestion(
        entityType: j['entityType'] ?? '',
        entityId: j['entityId'] ?? 0,
        label: j['label'] ?? '',
        context: j['context'],
        token: j['token'] ?? '',
      );
}

/// A resolved mention, positioned so the client can render a pill in place.
class MentionRef {
  final String entityType;
  final int entityId;
  final int startIndex;
  final int length;
  final String? label;
  final String? context;
  final String? statusLabel;
  final bool isAvailable;
  final bool hasAccess;

  MentionRef({
    required this.entityType,
    required this.entityId,
    required this.startIndex,
    required this.length,
    this.label,
    this.context,
    this.statusLabel,
    this.isAvailable = true,
    this.hasAccess = true,
  });

  factory MentionRef.fromJson(Map<String, dynamic> j) => MentionRef(
        entityType: j['entityType'] ?? '',
        entityId: j['entityId'] ?? 0,
        startIndex: j['startIndex'] ?? 0,
        length: j['length'] ?? 0,
        label: j['label'],
        context: j['context'],
        statusLabel: j['statusLabel'],
        isAvailable: j['isAvailable'] ?? true,
        hasAccess: j['hasAccess'] ?? true,
      );
}

class MessageAttachment {
  final int id;
  final AttachmentKind kind;

  /// Server-issued authorized route ("api/Conversations/attachments/{id}/content"),
  /// NOT a static path — access is membership-checked (risk E-R2). Resolve against
  /// the API root before use.
  final String url;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final int? durationSeconds;
  final bool isAnnotated;

  MessageAttachment({
    required this.id,
    required this.kind,
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.durationSeconds,
    this.isAnnotated = false,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> j) => MessageAttachment(
        id: j['id'] ?? 0,
        kind: _attachmentKindFrom(j['kind']),
        url: j['url'] ?? '',
        fileName: j['fileName'] ?? 'file',
        contentType: j['contentType'] ?? 'application/octet-stream',
        sizeBytes: j['sizeBytes'] ?? 0,
        durationSeconds: j['durationSeconds'],
        isAnnotated: j['isAnnotated'] ?? false,
      );
}

class ReplyPreview {
  final int id;
  final String? senderName;
  final String? snippet;
  final bool isDeleted;

  ReplyPreview({required this.id, this.senderName, this.snippet, this.isDeleted = false});

  factory ReplyPreview.fromJson(Map<String, dynamic> j) => ReplyPreview(
        id: j['id'] ?? 0,
        senderName: j['senderName'],
        snippet: j['snippet'],
        isDeleted: j['isDeleted'] ?? false,
      );
}

class ReactionSummary {
  final String emoji;
  final int count;
  final bool reactedByMe;

  ReactionSummary({required this.emoji, required this.count, required this.reactedByMe});

  factory ReactionSummary.fromJson(Map<String, dynamic> j) => ReactionSummary(
        emoji: j['emoji'] ?? '',
        count: j['count'] ?? 0,
        reactedByMe: j['reactedByMe'] ?? false,
      );
}

class Message {
  final int id;
  final int conversationId;
  final int sequenceNumber;
  final String clientMessageId;
  final int senderId;
  final String? senderName;
  final MessageType type;
  final String? body;
  final MessagePriority priority;
  final int? linkedIncidentId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final int? replyToMessageId;
  final ReplyPreview? replyToPreview;
  final List<ReactionSummary> reactions;
  final bool isPinned;
  final int editCount;
  final List<MessageAttachment> attachments;
  final List<MentionRef> mentions;

  // Read receipts — populated by the server only for the caller's own messages.
  final int readCount;
  final int recipientCount;
  final MessageReceiptState deliveryState;

  // Local-only.
  final PendingStatus? pendingStatus;

  Message({
    required this.id,
    required this.conversationId,
    required this.sequenceNumber,
    required this.clientMessageId,
    required this.senderId,
    this.senderName,
    required this.type,
    this.body,
    this.priority = MessagePriority.normal,
    this.linkedIncidentId,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.replyToMessageId,
    this.replyToPreview,
    this.reactions = const [],
    this.isPinned = false,
    this.editCount = 0,
    this.attachments = const [],
    this.mentions = const [],
    this.readCount = 0,
    this.recipientCount = 0,
    this.deliveryState = MessageReceiptState.sent,
    this.pendingStatus,
  });

  bool get isRead =>
      deliveryState == MessageReceiptState.read ||
      deliveryState == MessageReceiptState.acknowledged;

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] ?? 0,
        conversationId: j['conversationId'] ?? 0,
        sequenceNumber: j['sequenceNumber'] ?? 0,
        clientMessageId: j['clientMessageId']?.toString() ?? '',
        senderId: j['senderId'] ?? 0,
        senderName: j['senderName'],
        type: _messageTypeFrom(j['type']),
        body: j['body'],
        priority: _priorityFrom(j['priority']),
        linkedIncidentId: j['linkedIncidentId'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
        editedAt: j['editedAt'] != null ? DateTime.tryParse(j['editedAt'])?.toLocal() : null,
        isDeleted: j['isDeleted'] ?? false,
        replyToMessageId: j['replyToMessageId'],
        replyToPreview: j['replyToPreview'] != null
            ? ReplyPreview.fromJson(j['replyToPreview'])
            : null,
        reactions: (j['reactions'] as List<dynamic>? ?? [])
            .map((r) => ReactionSummary.fromJson(r))
            .toList(),
        isPinned: j['isPinned'] ?? false,
        editCount: j['editCount'] ?? 0,
        attachments: (j['attachments'] as List<dynamic>? ?? [])
            .map((a) => MessageAttachment.fromJson(a))
            .toList(),
        mentions: (j['mentions'] as List<dynamic>? ?? [])
            .map((m) => MentionRef.fromJson(m))
            .toList(),
        readCount: j['readCount'] ?? 0,
        recipientCount: j['recipientCount'] ?? 0,
        deliveryState: _receiptFrom(j['deliveryState']),
      );

  Message copyWithReactions(List<ReactionSummary> newReactions) => Message(
        id: id,
        conversationId: conversationId,
        sequenceNumber: sequenceNumber,
        clientMessageId: clientMessageId,
        senderId: senderId,
        senderName: senderName,
        type: type,
        body: body,
        priority: priority,
        linkedIncidentId: linkedIncidentId,
        createdAt: createdAt,
        editedAt: editedAt,
        isDeleted: isDeleted,
        replyToMessageId: replyToMessageId,
        replyToPreview: replyToPreview,
        reactions: newReactions,
        isPinned: isPinned,
        editCount: editCount,
        attachments: attachments,
        mentions: mentions,
        readCount: readCount,
        recipientCount: recipientCount,
        deliveryState: deliveryState,
        pendingStatus: pendingStatus,
      );

  Message copyWith({
    int? id,
    int? sequenceNumber,
    PendingStatus? pendingStatus,
    bool clearPending = false,
    int? readCount,
    int? recipientCount,
    MessageReceiptState? deliveryState,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      clientMessageId: clientMessageId,
      senderId: senderId,
      senderName: senderName,
      type: type,
      body: body,
      priority: priority,
      linkedIncidentId: linkedIncidentId,
      createdAt: createdAt,
      editedAt: editedAt,
      isDeleted: isDeleted,
      replyToMessageId: replyToMessageId,
      replyToPreview: replyToPreview,
      reactions: reactions,
      isPinned: isPinned,
      editCount: editCount,
      attachments: attachments,
      mentions: mentions,
      readCount: readCount ?? this.readCount,
      recipientCount: recipientCount ?? this.recipientCount,
      deliveryState: deliveryState ?? this.deliveryState,
      pendingStatus: clearPending ? null : (pendingStatus ?? this.pendingStatus),
    );
  }
}

class MessagePage {
  final List<Message> messages;
  final bool hasMoreOlder;
  final bool hasMoreNewer;

  MessagePage({required this.messages, required this.hasMoreOlder, required this.hasMoreNewer});

  factory MessagePage.fromJson(Map<String, dynamic> j) => MessagePage(
        messages: (j['messages'] as List<dynamic>? ?? [])
            .map((m) => Message.fromJson(m))
            .toList(),
        hasMoreOlder: j['hasMoreOlder'] ?? false,
        hasMoreNewer: j['hasMoreNewer'] ?? false,
      );
}
