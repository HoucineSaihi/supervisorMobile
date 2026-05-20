import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supervisormobile/features/VisualMerchandising/dtos/vm_submission_comment_dto.dart';
import 'package:supervisormobile/features/VisualMerchandising/services/vm_service.dart';

class SubmissionCommentsSheet extends StatefulWidget {
  final int campaignId;
  final int siteId;
  final String campaignName;

  final VoidCallback? onThreadOpened;

  const SubmissionCommentsSheet({
    super.key,
    required this.campaignId,
    required this.siteId,
    required this.campaignName,
    this.onThreadOpened,
  });

  /// [onThreadOpened] is called after a successful GET (thread marked read server-side).
  static Future<void> show(
    BuildContext context, {
    required int campaignId,
    required int siteId,
    required String campaignName,
    VoidCallback? onThreadOpened,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmissionCommentsSheet(
        campaignId: campaignId,
        siteId: siteId,
        campaignName: campaignName,
        onThreadOpened: onThreadOpened,
      ),
    );
  }

  @override
  State<SubmissionCommentsSheet> createState() =>
      _SubmissionCommentsSheetState();
}

class _SubmissionCommentsSheetState extends State<SubmissionCommentsSheet> {
  final VmService _service = VmService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<VmSubmissionCommentDto> _comments = [];
  int _unreadCountBeforeRead = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await _service.getSubmissionComments(
        campaignId: widget.campaignId,
        siteId: widget.siteId,
      );
      if (!mounted) return;
      setState(() {
        _comments = result.comments;
        _unreadCountBeforeRead = result.unreadCount;
        _isLoading = false;
      });
      widget.onThreadOpened?.call();
      _scrollToBottom(jump: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (jump) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Optimistic: append a placeholder comment immediately
    final optimistic = VmSubmissionCommentDto(
      id: -DateTime.now().millisecondsSinceEpoch,
      submissionId: 0,
      submissionRef: '',
      authorUserId: 0,
      authorName: 'Vous',
      authorInitials: 'V',
      authorRole: '',
      message: text,
      createdAt: DateTime.now().toUtc(),
    );

    setState(() {
      _isSending = true;
      _comments = [..._comments, optimistic];
      _textController.clear();
    });
    _scrollToBottom();

    try {
      final confirmed = await _service.postSubmissionComment(
        campaignId: widget.campaignId,
        siteId: widget.siteId,
        message: text,
      );
      if (!mounted) return;
      // Replace the optimistic entry with the confirmed one
      setState(() {
        _comments = [
          ..._comments.where((c) => c.id != optimistic.id),
          confirmed,
        ];
        _isSending = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      // Roll back the optimistic comment and restore the text
      setState(() {
        _comments = _comments.where((c) => c.id != optimistic.id).toList();
        _textController.text = text;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Échec de l\'envoi. Réessayez.'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Respect keyboard height so the input bar stays visible
    final bottomInset = mq.viewInsets.bottom;
    final sheetHeight = mq.size.height * 0.75 + bottomInset;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: sheetHeight.clamp(0.0, mq.size.height * 0.95),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _SheetHandle(),
          _SheetHeader(
            campaignName: widget.campaignName,
            unreadCount: _unreadCountBeforeRead,
          ),
          Expanded(child: _buildBody()),
          _buildInputBar(bottomInset),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E5FAA),
          strokeWidth: 2.5,
        ),
      );
    }
    if (_hasError) {
      return _ErrorState(onRetry: _load);
    }
    if (_comments.isEmpty) {
      return const _EmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: _comments.length,
      itemBuilder: (_, i) => _CommentBubble(comment: _comments[i]),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    final charCount = _textController.text.length;
    final nearLimit = charCount >= 450;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2EEF8))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB8D9F5), width: 1.2),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLength: 500,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un commentaire…',
                      hintStyle: TextStyle(
                        color: Color(0xFFB0C8E0),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF1B3F72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _textController.text.trim().isNotEmpty && !_isSending
                        ? const LinearGradient(
                            colors: [Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFB0C8E0), Color(0xFFB0C8E0)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: _textController.text.trim().isNotEmpty && !_isSending
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1E5FAA).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),

          if (nearLimit)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 52),
              child: Text(
                '$charCount / 500',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: charCount >= 500
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFFF5A623),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Handle drag ─────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFB8D9F5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ── En-tête dégradé ─────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final String campaignName;
  final int unreadCount;
  const _SheetHeader({
    required this.campaignName,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commentaires',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  campaignName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulle de commentaire ─────────────────────────────────
class _CommentBubble extends StatelessWidget {
  final VmSubmissionCommentDto comment;
  const _CommentBubble({required this.comment});

  static const List<Color> _avatarColors = [
    Color(0xFF1E5FAA),
    Color(0xFF27AE73),
    Color(0xFFF5A623),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF4A9EDD),
  ];

  // Optimistic comments have id < 0; give them a distinct muted style
  bool get _isOptimistic => comment.id < 0;

  Color get _avatarColor => _isOptimistic
      ? const Color(0xFFB0C8E0)
      : _avatarColors[comment.authorUserId.abs() % _avatarColors.length];

  String get _formattedTime {
    if (_isOptimistic) return 'Envoi…';
    final now = DateTime.now();
    final diff = now.difference(comment.createdAt.toLocal());
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    return DateFormat('dd/MM HH:mm').format(comment.createdAt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: _isOptimistic ? 0.6 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _avatarColor,
                shape: BoxShape.circle,
                boxShadow: _isOptimistic
                    ? []
                    : [
                        BoxShadow(
                          color: _avatarColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  comment.authorInitials.isNotEmpty
                      ? comment.authorInitials
                      : comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (comment.isUnread && !_isOptimistic)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: comment.isUnread && !_isOptimistic
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: Color(0xFF0F2D5E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8AB2D4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (comment.authorRole.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        comment.authorRole,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7BACD8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 5),

                  // Message bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(
                        color: const Color(0xFFE2EEF8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      comment.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1B3F72),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── État vide ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FD),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB8D9F5), width: 1.5),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF7BACD8),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucun commentaire',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3F72),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Soyez le premier à laisser\nun commentaire.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8AB2D4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── État erreur ──────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF3A9A0), width: 1.5),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFE74C3C),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Impossible de charger',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3F72),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Une erreur est survenue lors du\nchargement des commentaires.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8AB2D4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E5FAA), Color(0xFF4A9EDD)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
