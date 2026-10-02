import 'package:flutter/material.dart';

import '../../Profile/models/user_model.dart';
import '../../Profile/services/user_service.dart';
import '../controllers/conversation_controller.dart';
import '../models/conversation.dart';
import '../services/group_name.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';

/// "Add people" from a conversation's info screen — mobile counterpart of the web
/// details panel's add-members modal.
///
/// - In a group: the picked people are added in place.
/// - In a 1:1: a NEW named group is created with the other person plus the picked
///   people. The direct thread stays private and its history isn't copied, so the
///   screen says so up front. The name is pre-filled from the members and can be
///   changed.
///
/// Pops with the new group's [ConversationDetail] when one was created (the caller
/// opens it), or with null after adding to an existing group.
class AddPeopleScreen extends StatefulWidget {
  final ConversationController controller;

  const AddPeopleScreen({super.key, required this.controller});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _userService = UserService();
  final _search = TextEditingController();
  final _groupName = TextEditingController();

  bool _loading = true;
  bool _loadError = false;
  List<UserModel> _candidates = const [];
  final Map<int, UserModel> _selected = {};

  bool _nameEdited = false;
  bool _submitting = false;
  String? _error;

  ConversationController get c => widget.controller;
  bool get _isDirect => c.detail.value?.type == ConversationType.oneToOne;

  ConversationMember? get _counterpart => c.detail.value?.members
      .where((m) => m.caisseId != c.currentUserId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _refreshSuggestedName();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final all = await _userService.getAllUsers();
      // Not me, and not anyone already in the conversation.
      final existing = {
        c.currentUserId,
        ...?c.detail.value?.members.map((m) => m.caisseId),
      };
      if (!mounted) return;
      setState(() {
        _candidates = all.where((u) => !existing.contains(u.id)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  List<UserModel> get _filtered {
    final term = _search.text.trim().toLowerCase();
    if (term.isEmpty) return _candidates;
    return _candidates.where((u) {
      return (u.nom ?? '').toLowerCase().contains(term) ||
          (u.username ?? '').toLowerCase().contains(term) ||
          (u.role?.libelle ?? '').toLowerCase().contains(term);
    }).toList();
  }

  void _toggle(UserModel u) {
    setState(() {
      if (_selected.remove(u.id) == null) _selected[u.id] = u;
      _refreshSuggestedName();
    });
  }

  /// Follows the selection until the user types their own name.
  void _refreshSuggestedName() {
    if (!_isDirect || _nameEdited) return;
    _groupName.text = suggestGroupName([
      _counterpart?.name,
      ..._selected.values.map((u) => u.nom ?? u.username),
    ]);
  }

  void _onNameChanged(String value) {
    setState(() {
      _nameEdited = value.trim().isNotEmpty;
      if (!_nameEdited) _refreshSuggestedName();
    });
  }

  bool get _canSubmit =>
      !_submitting &&
      _selected.isNotEmpty &&
      (!_isDirect || _groupName.text.trim().isNotEmpty);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ids = _selected.keys.toList();
    try {
      if (_isDirect) {
        final created = await c.createGroupFromDirect(_groupName.text, ids);
        if (mounted) Navigator.of(context).pop(created);
      } else {
        await c.addMembers(ids);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _isDirect ? 'Could not create the group' : 'Could not add these people';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommColors.bg,
      appBar: AppBar(
        backgroundColor: CommColors.bg,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: CommColors.ink),
        title: Text(
          _isDirect ? 'New group' : 'Add people',
          style: const TextStyle(color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          if (_isDirect) _directNote(),
          if (_isDirect) _nameField(),
          if (_selected.isNotEmpty) _chips(),
          _searchField(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!, style: const TextStyle(color: CommColors.red, fontSize: 13)),
            ),
          Expanded(child: _list()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CommColors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: CommColors.line,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isDirect
                          ? 'Create group'
                          : _selected.isEmpty
                              ? 'Add people'
                              : 'Add ${_selected.length} ${_selected.length == 1 ? 'person' : 'people'}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _directNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: CommColors.blueDark),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This creates a new group. Your direct conversation stays private and its '
              'messages are not copied over.',
              style: TextStyle(fontSize: 12.5, color: CommColors.blueDark, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _groupName,
        onChanged: _onNameChanged,
        maxLength: groupNameMax,
        style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
        decoration: InputDecoration(
          labelText: 'Group name',
          hintText: 'e.g. Store launch team',
          counterText: '',
          helperText: !_nameEdited && _groupName.text.isNotEmpty
              ? 'Suggested from the members. You can change it.'
              : null,
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

  Widget _chips() {
    final users = _selected.values.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final u = users[i];
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
                    u.nom ?? u.username ?? 'User',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: CommColors.blueDark),
                  ),
                  GestureDetector(
                    onTap: () => _toggle(u),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: CommColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: CommColors.line),
          ),
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CommColors.blue));
    }
    if (_loadError) {
      return Center(
        child: TextButton(onPressed: _load, child: const Text("Couldn't load people. Retry")),
      );
    }
    final users = _filtered;
    if (users.isEmpty) {
      return const Center(
        child: Text('No people found', style: TextStyle(color: CommColors.muted)),
      );
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final selected = _selected.containsKey(u.id);
        return ListTile(
          onTap: _submitting ? null : () => _toggle(u),
          leading: CommAvatar(name: u.nom ?? u.username, seed: u.id, size: 38),
          title: Text(
            u.nom ?? u.username ?? 'User',
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w600, color: CommColors.ink),
          ),
          subtitle: u.role?.libelle != null
              ? Text(u.role!.libelle!,
                  style: const TextStyle(fontSize: 12, color: CommColors.muted))
              : null,
          trailing: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? CommColors.blue : CommColors.muted2,
          ),
        );
      },
    );
  }
}
