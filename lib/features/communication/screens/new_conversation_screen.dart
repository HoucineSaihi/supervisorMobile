import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Profile/models/user_model.dart';
import '../../Profile/services/user_service.dart';
import '../controllers/messenger_controller.dart';
import '../models/conversation.dart';
import '../services/group_name.dart';
import '../services/messenger_service.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';
import 'conversation_screen.dart';

enum _PickerTab { direct, group }

/// Start a Direct Message or a Group — the mobile counterpart of the web
/// new-conversation modal. Channels are deliberately absent here too: channel
/// membership is derived server-side from the org graph, never hand-picked.
///
/// The people list (`GET /Caisses`) is unscoped by design — same as web — so
/// filtering to "not me" and to the search term both happen client-side.
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _userService = UserService();
  final _messengerService = MessengerService();
  final _search = TextEditingController();
  final _groupTitle = TextEditingController();

  /// True once the user typed their own name. Until then the field follows the
  /// selection with a suggested name ("Ali, Sara, Karim") so naming never blocks.
  bool _groupTitleEdited = false;

  _PickerTab _tab = _PickerTab.direct;
  bool _isLoadingUsers = true;
  bool _hasLoadError = false;
  List<UserModel> _users = const [];
  String _searchTerm = '';

  final Set<int> _selectedIds = {};
  final Map<int, UserModel> _selectedById = {};

  /// Set only while a create call is in flight, for a specific row (direct tap)
  /// or the group footer button — disables the rest of the picker meanwhile.
  bool _isSubmitting = false;
  String? _submitError;

  int get _currentUserId => Get.find<MessengerController>().currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _search.addListener(() => setState(() => _searchTerm = _search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    _groupTitle.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _hasLoadError = false;
    });
    try {
      final all = await _userService.getAllUsers();
      // Never offer the current user as a conversation partner — the backend
      // rejects a self-DM and it is meaningless in a group too.
      final others = all.where((u) => u.id != _currentUserId).toList();
      if (!mounted) return;
      setState(() {
        _users = others;
        _isLoadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
        _hasLoadError = true;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    final term = _searchTerm.trim().toLowerCase();
    if (term.isEmpty) return _users;
    return _users.where((u) {
      final name = (u.nom ?? '').toLowerCase();
      final username = (u.username ?? '').toLowerCase();
      final role = (u.role?.libelle ?? '').toLowerCase();
      return name.contains(term) || username.contains(term) || role.contains(term);
    }).toList();
  }

  void _setTab(_PickerTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _submitError = null;
      // Switching back to Direct discards any in-progress group selection —
      // matches web: state only resets going group -> direct, not the reverse,
      // so the search term itself is deliberately left alone either way.
      if (tab == _PickerTab.direct) {
        _selectedIds.clear();
        _selectedById.clear();
        _groupTitle.clear();
        _groupTitleEdited = false;
      }
    });
  }

  /// Typing takes over from the suggestion; clearing the field hands it back.
  void _onGroupTitleChanged(String value) {
    setState(() {
      _groupTitleEdited = value.trim().isNotEmpty;
      if (!_groupTitleEdited) _refreshSuggestedTitle();
    });
  }

  /// Call inside setState.
  void _refreshSuggestedTitle() {
    if (_groupTitleEdited) return;
    _groupTitle.text = suggestGroupName(
      _selectedIds.map((id) => _selectedById[id]?.nom ?? _selectedById[id]?.username),
    );
  }

  void _toggleSelected(UserModel u) {
    final id = u.id;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedById.remove(id);
      } else {
        _selectedIds.add(id);
        _selectedById[id] = u;
      }
      _refreshSuggestedTitle();
    });
  }

  bool get _canCreateGroup =>
      _groupTitle.text.trim().isNotEmpty && _selectedIds.isNotEmpty && !_isSubmitting;

  Future<void> _createDirect(UserModel u) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      // The backend guards against duplicates: if a direct thread with this
      // user already exists it returns that one instead of creating a second,
      // so this can always be called unconditionally — same as web.
      final detail = await _messengerService.createDirectConversation(u.id);
      await _afterCreate(detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'Could not start the conversation';
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_canCreateGroup) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      final detail = await _messengerService.createGroupConversation(
        _groupTitle.text.trim(),
        _selectedIds.toList(),
      );
      await _afterCreate(detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'Could not create the group';
      });
    }
  }

  /// Reloads the inbox so the new thread shows up with server-computed fields,
  /// then replaces this picker with the thread itself.
  Future<void> _afterCreate(ConversationDetail detail) async {
    Get.find<MessengerController>().loadConversations(silent: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversationId: detail.id,
        title: detail.title ?? 'Conversation',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommColors.bg,
      appBar: AppBar(
        backgroundColor: CommColors.bg,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: CommColors.ink),
        title: const Text(
          'New conversation',
          style: TextStyle(color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          _tabSwitch(),
          if (_tab == _PickerTab.group) ...[
            _groupTitleField(),
            if (_selectedIds.isNotEmpty) _selectedChips(),
          ],
          _searchField(),
          if (_submitError != null) _errorBanner(),
          Expanded(child: _userListArea()),
        ],
      ),
      bottomNavigationBar: _tab == _PickerTab.group ? _groupFooter() : null,
    );
  }

  Widget _tabSwitch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CommColors.bgSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: CommColors.line),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton('Direct message', _PickerTab.direct)),
          Expanded(child: _tabButton('New group', _PickerTab.group)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _PickerTab tab) {
    final selected = _tab == tab;
    return GestureDetector(
      onTap: () => _setTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? CommColors.blueDark : CommColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _groupTitleField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _groupTitle,
        onChanged: _onGroupTitleChanged,
        maxLength: groupNameMax,
        style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
        decoration: InputDecoration(
          labelText: 'Group name',
          hintText: 'e.g. Store launch team',
          counterText: '',
          helperText: !_groupTitleEdited && _groupTitle.text.isNotEmpty
              ? 'Suggested from the members. You can change it.'
              : null,
          hintStyle: const TextStyle(color: CommColors.muted2),
          filled: true,
          fillColor: CommColors.bgSoft,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: const BorderSide(color: CommColors.blue),
          ),
        ),
      ),
    );
  }

  Widget _selectedChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedIds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final u = _selectedById[_selectedIds.elementAt(i)]!;
            final label = u.nom ?? u.username ?? 'User';
            return Container(
              padding: const EdgeInsets.only(left: 10, right: 4),
              decoration: BoxDecoration(
                color: CommColors.blueSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: CommColors.blueDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleSelected(u),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: CommColors.blueDark),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: _search,
        style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
        decoration: InputDecoration(
          hintText: 'Search people',
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

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        _submitError!,
        style: const TextStyle(color: CommColors.red, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _userListArea() {
    if (_isLoadingUsers) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: 6,
        itemBuilder: (_, __) => _skeletonRow(),
      );
    }
    if (_hasLoadError) {
      return _hint(
        icon: Icons.wifi_off,
        text: "Couldn't load people",
        action: TextButton(onPressed: _loadUsers, child: const Text('Retry')),
      );
    }
    final results = _filteredUsers;
    if (results.isEmpty) {
      return _hint(icon: Icons.person_search, text: 'No people found');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (_, i) => _userRow(results[i]),
    );
  }

  Widget _skeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: CommColors.line2, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 13, color: CommColors.line2),
                const SizedBox(height: 6),
                Container(width: 90, height: 11, color: CommColors.line2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(UserModel u) {
    final name = u.nom ?? u.username ?? 'User';
    final role = u.role?.libelle;
    final isGroup = _tab == _PickerTab.group;
    final selected = _selectedIds.contains(u.id);

    return InkWell(
      onTap: _isSubmitting
          ? null
          : (isGroup ? () => _toggleSelected(u) : () => _createDirect(u)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CommAvatar(name: name, seed: u.id, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: CommColors.ink,
                    ),
                  ),
                  if (role != null && role.isNotEmpty)
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: CommColors.muted),
                    ),
                ],
              ),
            ),
            if (isGroup)
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? CommColors.blue : CommColors.line,
                size: 22,
              )
            else if (_isSubmitting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: CommColors.blue),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hint({required IconData icon, required String text, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: CommColors.line),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CommColors.muted, fontSize: 13.5),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  Widget _groupFooter() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: CommColors.bg,
          border: Border(top: BorderSide(color: CommColors.line)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _canCreateGroup ? _createGroup : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CommColors.blue,
              disabledBackgroundColor: CommColors.muted2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Create group',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
          ),
        ),
      ),
    );
  }
}
