import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../controllers/messenger_controller.dart';
import '../models/conversation.dart';
import '../services/chat_signalr_service.dart' show ConnectionStatus;
import '../theme/comm_colors.dart';
import '../widgets/connection_banner.dart';
import '../widgets/conversation_actions_sheet.dart';
import '../widgets/conversation_card.dart';
import '../widgets/conversation_list_skeleton.dart';
import 'conversation_screen.dart';

/// Inbox: the list of the user's conversations. Entry screen of the messenger tab.
///
/// Stateful only to own the search field's controller — all list state lives on
/// [MessengerController], which is `permanent: true` and so survives the tab switches
/// that rebuild this widget from scratch.
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  late final MessengerController c;
  late final TextEditingController _search;

  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    // Created once by NavigationMenu (permanent) so the realtime channel is up on
    // every tab; fall back to creating it if this screen is ever shown standalone.
    c = Get.isRegistered<MessengerController>()
        ? Get.find<MessengerController>()
        : Get.put(MessengerController(), permanent: true);

    // Re-entering the tab with a search still applied would otherwise show a filtered
    // list above an empty-looking search box.
    _search = TextEditingController(text: c.searchQuery.value);
    _searchVisible = _search.text.isNotEmpty;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _search.clear();
        c.setSearchQuery('');
      }
    });
  }

  void _open(ConversationSummary conv) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversationId: conv.id,
        title: conv.title ?? 'Conversation',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommColors.bg,
      appBar: AppBar(
        backgroundColor: CommColors.bg,
        elevation: 0,
        titleSpacing: 16,
        title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: CommColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                _ConnectionLabel(status: c.connection.value),
              ],
            )),
        iconTheme: const IconThemeData(color: CommColors.ink),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            tooltip: _searchVisible ? 'Close search' : 'Search',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CommColors.blue,
        onPressed: _showNewConversationSheet,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: Column(
        children: [
          Obx(() => ConnectionBanner(
                status: c.connection.value,
                onRetry: () => c.signalR.connect().catchError((_) {}),
              )),
          Obx(() {
            if (c.pendingOutbox.value == 0) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: CommColors.blueSoft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                '${c.pendingOutbox.value} message(s) waiting to send',
                style: const TextStyle(
                  color: CommColors.blueDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          if (_searchVisible) _searchField(),
          _filterChips(),
          Expanded(child: Obx(_buildBody)),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: TextField(
        controller: _search,
        autofocus: true,
        onChanged: c.setSearchQuery,
        style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: const TextStyle(color: CommColors.muted2),
          prefixIcon: const Icon(Icons.search, size: 20, color: CommColors.muted2),
          filled: true,
          fillColor: CommColors.bgSoft,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: CommColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: CommColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: CommColors.blue),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 46,
      child: Obx(() {
        final active = c.filter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          itemCount: ConversationFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = ConversationFilter.values[i];
            final selected = f == active;
            final count = _countFor(f);
            return GestureDetector(
              onTap: () => c.setFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? CommColors.blue : CommColors.bgSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? CommColors.blue : CommColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : CommColors.ink2,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : CommColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : CommColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  int _countFor(ConversationFilter f) {
    switch (f) {
      case ConversationFilter.all:
        return c.conversations.length;
      case ConversationFilter.unread:
        return c.conversations.where((x) => x.unreadCount > 0).length;
      case ConversationFilter.mentions:
        return c.conversations.where((x) => x.hasUnreadMention).length;
      case ConversationFilter.groups:
        return c.conversations.where((x) => !x.isDirect).length;
    }
  }

  Widget _buildBody() {
    if (c.isLoading.value && c.conversations.isEmpty) {
      return const ConversationListSkeleton();
    }

    // Checked before the empty states so a failed load never reads as "no results".
    if (c.hasError.value && c.conversations.isEmpty) {
      return _stateMessage(
        Icons.wifi_off,
        'Could not load conversations',
        detail: 'Showing nothing cached yet — check your connection.',
        action: TextButton(
          onPressed: c.loadConversations,
          child: const Text('Retry'),
        ),
      );
    }

    if (c.conversations.isEmpty) {
      return _stateMessage(
        Icons.forum_outlined,
        'No conversations yet',
        detail: 'Start a discussion and it will show up here.',
        action: TextButton(
          onPressed: _showNewConversationSheet,
          child: const Text('New conversation'),
        ),
      );
    }

    final pinned = c.pinnedConversations;
    final rest = c.unpinnedConversations;

    if (pinned.isEmpty && rest.isEmpty) {
      return _stateMessage(
        Icons.search_off,
        'Nothing found',
        detail: 'No conversation matches this filter or search.',
        action: TextButton(
          onPressed: () {
            _search.clear();
            c.clearFilters();
          },
          child: const Text('Clear filters'),
        ),
      );
    }

    final expanded = c.pinnedExpanded.value;
    final shownPinned = expanded ? pinned : pinned.take(3).toList();

    return RefreshIndicator(
      color: CommColors.blue,
      onRefresh: c.loadConversations,
      child: ListView(
        // Survives the tab-switch rebuild, which a State-held ScrollController would not.
        key: const PageStorageKey<String>('messenger_conversation_list'),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          if (pinned.isNotEmpty) ...[
            _sectionHeader(
              'Pinned',
              trailing: pinned.length > 3
                  ? TextButton(
                      onPressed: c.pinnedExpanded.toggle,
                      child: Text(expanded ? 'Show less' : 'View all'),
                    )
                  : null,
            ),
            ...shownPinned.map(_row),
            if (rest.isNotEmpty) _sectionHeader('All conversations'),
          ],
          ...rest.map(_row),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, trailing == null ? 16 : 6, 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: CommColors.muted,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _row(ConversationSummary conv) {
    return Slidable(
      key: ValueKey(conv.id),
      // Archive and delete are absent on purpose: neither has a backing endpoint.
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: conv.unreadCount > 0 ? 0.5 : 0.25,
        children: [
          if (conv.unreadCount > 0)
            SlidableAction(
              onPressed: (_) => c.markReadFromInbox(conv.id),
              backgroundColor: CommColors.blue,
              foregroundColor: Colors.white,
              icon: Icons.mark_email_read_outlined,
              label: 'Read',
            ),
          SlidableAction(
            onPressed: (_) => c.togglePin(conv.id),
            backgroundColor: CommColors.amber,
            foregroundColor: Colors.white,
            icon: conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: conv.isPinned ? 'Unpin' : 'Pin',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              if (conv.isMuted) {
                c.toggleMute(conv.id, until: null);
              } else {
                c.toggleMute(conv.id, until: DateTime.now().add(const Duration(days: 7)));
              }
            },
            backgroundColor: CommColors.muted,
            foregroundColor: Colors.white,
            icon: conv.isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            label: conv.isMuted ? 'Unmute' : 'Mute',
          ),
        ],
      ),
      child: ConversationCard(
        conversation: conv,
        onTap: () => _open(conv),
        onLongPress: () => showConversationActions(
          context,
          c,
          conv,
          onOpen: () => _open(conv),
        ),
      ),
    );
  }

  Widget _stateMessage(
    IconData icon,
    String text, {
    String? detail,
    Widget? action,
  }) {
    // Scrollable so pull-to-refresh still works from an empty inbox.
    return LayoutBuilder(
      builder: (_, constraints) => RefreshIndicator(
        color: CommColors.blue,
        onRefresh: c.loadConversations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 40, color: CommColors.line),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CommColors.ink2,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CommColors.muted, fontSize: 13),
                      ),
                    ],
                    if (action != null) action,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewConversationSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'New conversation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CommColors.ink,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: CommColors.line2),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Text(
                  'Choosing who to message needs the people picker, which is not built '
                  'on mobile yet. For now, start the conversation from the web app or '
                  'from an incident, mission or campaign — it will appear here.',
                  style: TextStyle(color: CommColors.muted, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small presence line under the title, so the header carries connection state without
/// waiting for the banner to appear.
class _ConnectionLabel extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = switch (status) {
      ConnectionStatus.connected => ('Online', CommColors.green),
      ConnectionStatus.connecting => ('Connecting…', CommColors.amber),
      ConnectionStatus.reconnecting => ('Reconnecting…', CommColors.amber),
      ConnectionStatus.offline => ('Offline', CommColors.red),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            color: CommColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
