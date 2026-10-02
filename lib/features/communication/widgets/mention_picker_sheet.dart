import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';

import '../controllers/conversation_controller.dart';
import '../models/message.dart';
import '../theme/comm_colors.dart';

/// The composer's "@" button: a guided alternative to typing "@" inline. Mirrors the
/// web's mention picker.
///
/// Step 1 asks what to mention (person, incident, mission, store, campaign); step 2
/// is a search scoped to that type, so an incident number or a store name finds the
/// right thing without knowing the inline syntax. Step 2 opens with suggestions
/// (recently mentioned here, then newest open items) before anything is typed.
///
/// Resolves to the picked suggestion, or null if dismissed.
Future<MentionSuggestion?> showMentionPicker(
    BuildContext context, ConversationController controller) {
  return showModalBottomSheet<MentionSuggestion>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => Padding(
      // Keeps the search field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _MentionPickerSheet(controller: controller),
    ),
  );
}

class _MentionKind {
  final String type;
  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final Color fg;
  final Color bg;

  const _MentionKind(
      this.type, this.title, this.description, this.hint, this.icon, this.fg, this.bg);
}

const _kinds = [
  _MentionKind('User', 'A person', 'Someone in this conversation', 'Search a person by name…',
      Icons.person_outline, CommColors.blue, CommColors.blueSoft),
  _MentionKind('Incident', 'An incident', 'Find it by number or keyword',
      'Incident number or keyword…', Icons.report_problem_outlined, Color(0xFFDC2626),
      Color(0xFFFEF2F2)),
  _MentionKind('Mission', 'A mission', 'By name, code or number', 'Mission name, code or number…',
      Icons.assignment_outlined, Color(0xFFB45309), Color(0xFFFFFBEB)),
  _MentionKind('Boutique', 'A store', 'By name, code or city', 'Store name, code or city…',
      Icons.store_outlined, Color(0xFF15803D), Color(0xFFF0FDF4)),
  _MentionKind('Campaign', 'A campaign', 'By name or code', 'Campaign name or code…',
      Icons.campaign_outlined, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
];

_MentionKind _kindOf(String type) =>
    _kinds.firstWhere((k) => k.type == type, orElse: () => _kinds.first);

class _MentionPickerSheet extends StatefulWidget {
  final ConversationController controller;

  const _MentionPickerSheet({required this.controller});

  @override
  State<_MentionPickerSheet> createState() => _MentionPickerSheetState();
}

class _MentionPickerSheetState extends State<_MentionPickerSheet> {
  final _search = TextEditingController();

  _MentionKind? _kind;
  List<MentionSuggestion> _results = const [];
  bool _loading = false;

  Timer? _debounce;
  CancelToken? _cancel;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _choose(_MentionKind kind) {
    setState(() {
      _kind = kind;
      _results = const [];
    });
    _search.clear();
    _runSearch('');
  }

  void _back() {
    _seq++;
    _debounce?.cancel();
    _cancel?.cancel();
    setState(() {
      _kind = null;
      _results = const [];
      _loading = false;
    });
  }

  /// Debounced, and a newer keystroke cancels the older request; [_seq] drops any
  /// reply that still lands late.
  void _runSearch(String raw) {
    final kind = _kind;
    if (kind == null) return;
    final query = raw.trim();
    final seq = ++_seq;
    _debounce?.cancel();
    _cancel?.cancel();

    setState(() => _loading = true);
    // People are filtered locally — no point waiting.
    final delay = kind.type == 'User' ? Duration.zero : const Duration(milliseconds: 220);
    _debounce = Timer(delay, () async {
      final cancel = _cancel = CancelToken();
      List<MentionSuggestion> list;
      try {
        list = await widget.controller.searchMentions(kind.type, query, cancelToken: cancel);
      } catch (_) {
        list = const [];
      }
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    });
  }

  /// One non-numeric letter: the server only searches from two characters.
  bool get _needsMoreInput {
    final q = _search.text.trim();
    return _kind?.type != 'User' && q.length == 1 && int.tryParse(q) == null;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: CommColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _header(),
            const Divider(height: 1, color: CommColors.line2),
            if (_kind == null) _typeList() else Flexible(child: _searchStep(_kind!)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final kind = _kind;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
      child: Row(
        children: [
          if (kind != null)
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, color: CommColors.ink, size: 22),
              onPressed: _back,
            )
          else
            const SizedBox(width: 12),
          if (kind != null) ...[
            _badge(kind, size: 28, iconSize: 16),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              kind?.title ?? 'What do you want to mention?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: CommColors.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: CommColors.muted, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _badge(_MentionKind kind, {double size = 40, double iconSize = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kind.bg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(kind.icon, size: iconSize, color: kind.fg),
    );
  }

  // ── Step 1 ────────────────────────────────────────────

  Widget _typeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in _kinds)
            InkWell(
              onTap: () => _choose(kind),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    _badge(kind),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kind.title,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: CommColors.ink)),
                          const SizedBox(height: 2),
                          Text(kind.description,
                              style: const TextStyle(fontSize: 12.5, color: CommColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: CommColors.muted2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────

  Widget _searchStep(_MentionKind kind) {
    final hasQuery = _search.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: TextField(
            controller: _search,
            autofocus: true,
            onChanged: _runSearch,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (_results.isNotEmpty) Navigator.of(context).pop(_results.first);
            },
            style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
            decoration: InputDecoration(
              hintText: kind.hint,
              hintStyle: const TextStyle(color: CommColors.muted2),
              prefixIcon: const Icon(Icons.search, size: 20, color: CommColors.muted2),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CommColors.blue),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: CommColors.bgSoft,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CommColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CommColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
              ),
            ),
          ),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
            child: Text(
              hasQuery ? 'RESULTS' : 'SUGGESTED',
              style: const TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
                color: CommColors.muted2,
              ),
            ),
          ),
        Flexible(
          child: _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Text(
                    _loading
                        ? 'Searching…'
                        : _needsMoreInput
                            ? 'Keep typing to search, or enter a number'
                            : 'Nothing found. Check the spelling or try a number.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: CommColors.muted),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 10),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => _resultRow(_results[i]),
                ),
        ),
      ],
    );
  }

  Widget _resultRow(MentionSuggestion s) {
    final kind = _kindOf(s.entityType);
    final ctx = s.context?.trim();
    return InkWell(
      onTap: () => Navigator.of(context).pop(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Row(
          children: [
            _badge(kind, size: 34, iconSize: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.label.isEmpty ? '${s.entityType} #${s.entityId}' : s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: CommColors.ink),
                  ),
                  if (ctx != null && ctx.isNotEmpty)
                    Text(
                      ctx,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: CommColors.muted),
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
