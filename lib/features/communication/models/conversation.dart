// Dart mirror of the backend ConversationDto family and the Angular
// conversation.model.ts.

import 'message.dart' show MessagePriority, priorityFrom;

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

/// What operational object a conversation is attached to, mirroring the backend's
/// ConversationScopeType. A `ContextThread` created from an Incident/Mission/Campaign/
/// store carries the object here, which is what lets a list row show an origin badge.
///
/// The backend enum also has a `User` member, but that is only ever used for message
/// mentions (MessageEntityRef), never as a conversation's scope — omitted deliberately.
enum ConversationScopeType {
  none,
  boutique,
  group,
  role,
  campaign,
  incident,
  mission,
  audit,
  correctiveAction,
  vmExecution,
  checklist,
}

/// Enums cross the wire as strings (`JsonStringEnumConverter` is registered globally in
/// the backend's Program.cs), so these are the exact PascalCase names it emits.
ConversationScopeType _scopeTypeFrom(String? v) {
  switch (v) {
    case 'Boutique':
      return ConversationScopeType.boutique;
    case 'Group':
      return ConversationScopeType.group;
    case 'Role':
      return ConversationScopeType.role;
    case 'Campaign':
      return ConversationScopeType.campaign;
    case 'Incident':
      return ConversationScopeType.incident;
    case 'Mission':
      return ConversationScopeType.mission;
    case 'Audit':
      return ConversationScopeType.audit;
    case 'CorrectiveAction':
      return ConversationScopeType.correctiveAction;
    case 'VmExecution':
      return ConversationScopeType.vmExecution;
    case 'Checklist':
      return ConversationScopeType.checklist;
    default:
      return ConversationScopeType.none;
  }
}

/// Inverse of [_scopeTypeFrom]. Kept as a matched pair the way message.dart pairs
/// `priorityFrom`/`priorityToJson`, so the badge widget can reuse the shared
/// entity-type visual lookup that is keyed by these same backend names.
String scopeTypeToJson(ConversationScopeType t) {
  switch (t) {
    case ConversationScopeType.boutique:
      return 'Boutique';
    case ConversationScopeType.group:
      return 'Group';
    case ConversationScopeType.role:
      return 'Role';
    case ConversationScopeType.campaign:
      return 'Campaign';
    case ConversationScopeType.incident:
      return 'Incident';
    case ConversationScopeType.mission:
      return 'Mission';
    case ConversationScopeType.audit:
      return 'Audit';
    case ConversationScopeType.correctiveAction:
      return 'CorrectiveAction';
    case ConversationScopeType.vmExecution:
      return 'VmExecution';
    case ConversationScopeType.checklist:
      return 'Checklist';
    case ConversationScopeType.none:
      return 'None';
  }
}

/// Lifecycle of the incident / VM campaign / VM execution / mission a conversation is
/// about, as the server derives it on every fetch (ScopeStatusService). Grouped into one
/// value because summary, detail and the list row all carry exactly these four fields.
class ScopeStatus {
  /// The object's own status key — "InProgress", "Solved", "Cancelled"… See [label].
  final String key;
  final bool isClosed;
  final DateTime? closedAt;

  /// No sending, editing or reacting. The server rejects them with "ConversationClosed".
  final bool isReadOnly;

  const ScopeStatus({
    required this.key,
    required this.isClosed,
    this.closedAt,
    this.isReadOnly = false,
  });

  /// Null when the conversation isn't about such an object (DMs, groups, stores).
  static ScopeStatus? fromJson(Map<String, dynamic> j) {
    final key = j['scopeStatus'] as String?;
    if (key == null) return null;
    return ScopeStatus(
      key: key,
      isClosed: j['scopeState'] == 'Closed',
      closedAt: j['scopeClosedAt'] != null
          ? DateTime.tryParse(j['scopeClosedAt'])?.toLocal()
          : null,
      isReadOnly: j['isReadOnly'] ?? false,
    );
  }

  String get label => _labels[key] ?? key;

  static const _labels = {
    'Open': 'Open',
    'Declared': 'Declared',
    'AwaitingConfirmation': 'Awaiting confirmation',
    'Pending': 'Pending',
    'Acknowledged': 'Acknowledged',
    'Planned': 'Planned',
    'InProgress': 'In progress',
    'NeedsReview': 'Needs review',
    'Reopened': 'Reopened',
    'Solved': 'Solved',
    'Planified': 'Planned',
    'Completed': 'Completed',
    'Cancelled': 'Cancelled',
    'NotStarted': 'Not started',
    'Rejected': 'Rejected',
    'Validated': 'Validated',
    'Ended': 'Ended',
  };
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

  /// Pinned by *this* user — the backend stores it per-member, so one person pinning a
  /// busy group never reorders it for anyone else.
  final bool isPinned;

  /// When the mute expires. Null while unmuted; [isMuted] is the server's already-
  /// evaluated "is it still in effect right now" answer, so prefer that for display.
  final DateTime? mutedUntil;

  /// Highest severity among the *unread* messages, or null when there is nothing unread
  /// or it is all routine. Drives the row's urgency dot and clears once the thread is
  /// read. Server-computed per fetch — never persisted.
  final MessagePriority? highestUnreadPriority;

  /// True when an unread message in here @-mentions this user. Backs the Mentions filter.
  final bool hasUnreadMention;

  /// The operational object this thread hangs off, when it is a context thread.
  final ConversationScopeType scopeType;
  final int? scopeId;

  /// Status of that object; null when there is none. Drives the row's status pill.
  final ScopeStatus? scopeStatus;

  bool get isClosed => scopeStatus?.isClosed ?? false;

  /// Read watermark inputs. Needed to mark the thread read from the list without
  /// opening it — the server's `/read` endpoint wants both a message id and a sequence.
  final int? lastMessageId;
  final int? lastMessageSequence;

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
    this.isPinned = false,
    this.mutedUntil,
    this.highestUnreadPriority,
    this.hasUnreadMention = false,
    this.scopeType = ConversationScopeType.none,
    this.scopeId,
    this.scopeStatus,
    this.lastMessageId,
    this.lastMessageSequence,
  });

  bool get isDirect => type == ConversationType.oneToOne;

  /// A context thread worth badging — i.e. it came from a real operational object.
  bool get hasScope => scopeType != ConversationScopeType.none && scopeId != null;

  /// Urgency worth drawing attention to. Routine traffic deliberately gets no dot:
  /// badging every unread conversation would defeat the point of the badge.
  bool get isUrgent =>
      highestUnreadPriority != null && highestUnreadPriority != MessagePriority.normal;

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
      isPinned: j['isPinned'] ?? false,
      mutedUntil: j['mutedUntil'] != null
          ? DateTime.tryParse(j['mutedUntil'])?.toLocal()
          : null,
      // Absent until the server-side rollup ships; parses as "no badge" until then.
      highestUnreadPriority: j['highestUnreadPriority'] != null
          ? priorityFrom(j['highestUnreadPriority'])
          : null,
      hasUnreadMention: j['hasUnreadMention'] ?? false,
      scopeType: _scopeTypeFrom(j['scopeType']),
      scopeId: j['scopeId'],
      scopeStatus: ScopeStatus.fromJson(j),
      lastMessageId: (last?['id'] as num?)?.toInt(),
      lastMessageSequence: (last?['sequenceNumber'] as num?)?.toInt(),
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

  /// Optimistic-update helper.
  ///
  /// [clearMutedUntil] and [clearUnreadPriority] exist because a plain optional named
  /// parameter cannot distinguish "set this to null" from "leave it alone" — and both
  /// unmuting and clearing the urgency dot on read need to express exactly that.
  ConversationSummary copyWith({
    int? unreadCount,
    bool? isMuted,
    DateTime? mutedUntil,
    bool clearMutedUntil = false,
    bool? isPinned,
    MessagePriority? highestUnreadPriority,
    bool clearUnreadPriority = false,
    bool? hasUnreadMention,
    String? lastMessagePreview,
    String? lastMessageSenderName,
    DateTime? lastMessageAt,
    int? lastMessageId,
    int? lastMessageSequence,
  }) =>
      ConversationSummary(
        id: id,
        type: type,
        title: title,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted ?? this.isMuted,
        memberCount: memberCount,
        isOnline: isOnline,
        avatarUrl: avatarUrl,
        isPinned: isPinned ?? this.isPinned,
        mutedUntil: clearMutedUntil ? null : (mutedUntil ?? this.mutedUntil),
        highestUnreadPriority: clearUnreadPriority
            ? null
            : (highestUnreadPriority ?? this.highestUnreadPriority),
        hasUnreadMention: hasUnreadMention ?? this.hasUnreadMention,
        scopeType: scopeType,
        scopeId: scopeId,
        scopeStatus: scopeStatus,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        lastMessageSequence: lastMessageSequence ?? this.lastMessageSequence,
      );
}

class ConversationListResponse {
  final List<ConversationSummary> conversations;
  final int page;
  final bool hasMore;

  /// Opaque keyset cursor for the next page; null on the last page.
  final String? nextCursor;

  /// Filter-chip totals — only sent with a first page (no cursor).
  final ConversationCounts? counts;

  /// The server JSON this response was parsed from — stored as-is by the local cache.
  final Map<String, dynamic>? raw;

  ConversationListResponse({
    required this.conversations,
    required this.page,
    required this.hasMore,
    this.nextCursor,
    this.counts,
    this.raw,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> j) => ConversationListResponse(
        conversations: (j['conversations'] as List<dynamic>? ?? [])
            .map((c) => ConversationSummary.fromJson(c))
            .toList(),
        page: j['page'] ?? 1,
        hasMore: j['hasMore'] ?? false,
        nextCursor: j['nextCursor'] as String?,
        counts: j['counts'] is Map<String, dynamic>
            ? ConversationCounts.fromJson(j['counts'] as Map<String, dynamic>)
            : null,
        raw: j,
      );
}

/// Server-side totals for the inbox chips — counted over every conversation, not
/// just the loaded pages.
class ConversationCounts {
  final int all;
  final int unread;
  final int direct;
  final int groups;
  final int mentions;

  /// Conversations whose incident / campaign / execution / mission is closed.
  final int closed;

  const ConversationCounts({
    this.all = 0,
    this.unread = 0,
    this.direct = 0,
    this.groups = 0,
    this.mentions = 0,
    this.closed = 0,
  });

  factory ConversationCounts.fromJson(Map<String, dynamic> j) => ConversationCounts(
        all: (j['all'] as num?)?.toInt() ?? 0,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        direct: (j['direct'] as num?)?.toInt() ?? 0,
        groups: (j['groups'] as num?)?.toInt() ?? 0,
        mentions: (j['mentions'] as num?)?.toInt() ?? 0,
        closed: (j['closed'] as num?)?.toInt() ?? 0,
      );
}

class ConversationMember {
  final int caisseId;
  final String? name;
  final String role;

  /// Job role ("Store manager"…), shown under the name in the @-menu.
  final String? roleName;

  ConversationMember({required this.caisseId, this.name, this.role = 'Member', this.roleName});

  factory ConversationMember.fromJson(Map<String, dynamic> j) => ConversationMember(
        caisseId: j['caisseId'] ?? 0,
        name: j['name'],
        role: j['role'] ?? 'Member',
        roleName: j['roleName'],
      );
}

class ConversationDetail {
  final int id;
  final ConversationType type;
  final String? title;
  final List<ConversationMember> members;

  /// The operational object this thread belongs to, when it is a context thread.
  /// Drives the header's context banner so nobody has to ask what is being discussed.
  final ConversationScopeType scopeType;
  final int? scopeId;

  /// Status of that object — refetched on ConversationUpdated, which the server sends
  /// when it opens or closes, so the composer locks and unlocks live.
  final ScopeStatus? scopeStatus;

  final bool isMuted;
  final bool isPinned;
  final DateTime? createdAt;
  final String? createdByName;

  ConversationDetail({
    required this.id,
    required this.type,
    this.title,
    this.members = const [],
    this.scopeType = ConversationScopeType.none,
    this.scopeId,
    this.scopeStatus,
    this.isMuted = false,
    this.isPinned = false,
    this.createdAt,
    this.createdByName,
  });

  bool get hasScope => scopeType != ConversationScopeType.none && scopeId != null;

  /// Its incident / campaign is closed: no sending, editing or reacting.
  bool get isReadOnly => scopeStatus?.isReadOnly ?? false;

  /// Members still in the conversation — the header's "N members" count.
  int get activeMemberCount => members.length;

  factory ConversationDetail.fromJson(Map<String, dynamic> j) => ConversationDetail(
        id: j['id'] ?? 0,
        type: _typeFrom(j['type']),
        title: j['displayName'] ?? j['title'],
        members: (j['members'] as List<dynamic>? ?? [])
            .map((m) => ConversationMember.fromJson(m))
            .toList(),
        scopeType: _scopeTypeFrom(j['scopeType']),
        scopeId: j['scopeId'],
        scopeStatus: ScopeStatus.fromJson(j),
        isMuted: j['isMuted'] ?? false,
        isPinned: j['isPinned'] ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'])?.toLocal()
            : null,
        createdByName: j['createdByName'],
      );
}

/// One label/value row of the context sheet. Mirrors ConversationContextFieldDto.
class ConversationContextField {
  /// Stable id ("Store", "AssignedTo"…) — see [label].
  final String key;
  final String value;

  /// text | date | datetime | number | percent. Dates arrive as ISO 8601.
  final String kind;

  const ConversationContextField({required this.key, required this.value, this.kind = 'text'});

  factory ConversationContextField.fromJson(Map<String, dynamic> j) => ConversationContextField(
        key: j['key'] ?? '',
        value: j['value'] ?? '',
        kind: j['kind'] ?? 'text',
      );

  String get label => _labels[key] ?? key;

  static const _labels = {
    'Store': 'Store',
    'Type': 'Type',
    'Department': 'Department',
    'AssignedTo': 'Assigned to',
    'DeclaredBy': 'Declared by',
    'DeclaredOn': 'Declared on',
    'PlannedFor': 'Planned for',
    'Code': 'Code',
    'StartDate': 'Start date',
    'EndDate': 'End date',
    'Stores': 'Stores',
    'Campaign': 'Campaign',
    'Zone': 'Zone',
    'ComplianceScore': 'Compliance score',
    'ExecutedAt': 'Executed on',
    'Agent': 'Agent',
    'StartedAt': 'Started on',
    'EndedAt': 'Ended on',
  };
}

/// What a scoped conversation is about (GET /Conversations/{id}/context): the same
/// shape for an incident, VM campaign, VM execution or mission. Mirrors
/// ConversationContextDto.
class ConversationContext {
  final int conversationId;
  final ConversationScopeType scopeType;
  final int scopeId;
  final String title;
  final String? subtitle;
  final ScopeStatus? status;
  final List<ConversationContextField> fields;

  /// Where "Open" leads: the campaign (executed per store — [siteIds] are its stores),
  /// an execution's campaign + [siteId], and the raw mission status the mission
  /// screen expects.
  final int? campaignId;
  final int? siteId;
  final List<int> siteIds;
  final int? missionStatus;

  ConversationContext({
    required this.conversationId,
    required this.scopeType,
    required this.scopeId,
    required this.title,
    this.subtitle,
    this.status,
    this.fields = const [],
    this.campaignId,
    this.siteId,
    this.siteIds = const [],
    this.missionStatus,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> j) => ConversationContext(
        conversationId: j['conversationId'] ?? 0,
        scopeType: _scopeTypeFrom(j['scopeType']),
        scopeId: j['scopeId'] ?? 0,
        title: j['title'] ?? '',
        subtitle: j['subtitle'],
        status: ScopeStatus.fromJson(j),
        fields: (j['fields'] as List<dynamic>? ?? [])
            .map((f) => ConversationContextField.fromJson(f as Map<String, dynamic>))
            .toList(),
        campaignId: (j['campaignId'] as num?)?.toInt(),
        siteId: (j['siteId'] as num?)?.toInt(),
        siteIds: (j['siteIds'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList(),
        missionStatus: (j['missionStatus'] as num?)?.toInt(),
      );
}

/// Status projection for the in-thread incident card. Mirrors IncidentStatusSummaryDto.
class IncidentStatusSummary {
  final int id;
  final String? description;
  final int? status;
  final String? statusLabel;
  final int? boutiqueId;
  final String? boutiqueName;
  final int? assignedTo;
  final String? assignedToName;
  final DateTime? declarationDate;
  final DateTime? closedDate;

  IncidentStatusSummary({
    required this.id,
    this.description,
    this.status,
    this.statusLabel,
    this.boutiqueId,
    this.boutiqueName,
    this.assignedTo,
    this.assignedToName,
    this.declarationDate,
    this.closedDate,
  });

  bool get isClosed => closedDate != null;

  factory IncidentStatusSummary.fromJson(Map<String, dynamic> j) => IncidentStatusSummary(
        id: j['id'] ?? 0,
        description: j['description'],
        status: j['status'],
        statusLabel: j['statusLabel'],
        boutiqueId: j['boutiqueId'],
        boutiqueName: j['boutiqueName'],
        assignedTo: j['assignedTo'],
        assignedToName: j['assignedToName'],
        declarationDate: j['declarationDate'] != null
            ? DateTime.tryParse(j['declarationDate'])?.toLocal()
            : null,
        closedDate: j['closedDate'] != null
            ? DateTime.tryParse(j['closedDate'])?.toLocal()
            : null,
      );
}

class BoutiqueOption {
  final int id;

  /// Store code — shown next to the name and searchable in the picker.
  final String? code;
  final String? libelle;

  BoutiqueOption({required this.id, this.code, this.libelle});

  factory BoutiqueOption.fromJson(Map<String, dynamic> j) =>
      BoutiqueOption(id: j['id'] ?? 0, code: j['code'] as String?, libelle: j['libelle']);

  String get label => libelle ?? 'Store #$id';
}

/// Whether the caller may convert this message and, when the sender has no
/// single fixed store of their own (an area manager or admin), which stores the
/// incident may be declared under. Mirrors ConvertToIncidentOptionsDto.
///
/// Without this the convert call 400s with "BoutiqueRequired" for any message
/// sent by someone who isn't tied to one store.
class ConvertToIncidentOptions {
  final bool canConvert;
  final bool requiresBoutiqueSelection;
  final List<BoutiqueOption> boutiques;

  ConvertToIncidentOptions({
    required this.canConvert,
    required this.requiresBoutiqueSelection,
    this.boutiques = const [],
  });

  factory ConvertToIncidentOptions.fromJson(Map<String, dynamic> j) =>
      ConvertToIncidentOptions(
        canConvert: j['canConvert'] ?? false,
        requiresBoutiqueSelection: j['requiresBoutiqueSelection'] ?? false,
        boutiques: (j['boutiques'] as List<dynamic>? ?? [])
            .map((b) => BoutiqueOption.fromJson(b))
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
