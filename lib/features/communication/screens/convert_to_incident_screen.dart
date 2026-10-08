import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../calendar/models/departement.dart';
import '../../calendar/services/missionService.dart';
import '../../incidents/models/Coefficient.dart';
import '../../incidents/services/incident_service.dart';
import '../controllers/conversation_controller.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../theme/comm_colors.dart';
import '../widgets/auth_image.dart';

/// Convert-to-incident form, opened from a message's long-press actions.
///
/// Collects the same fields the manual incident form does (description,
/// commentaire, priority, département) so an incident raised from chat is
/// indistinguishable from one declared by hand. The message seeds the form:
/// its body becomes the description, and an image message's photo becomes the
/// "before" evidence without a re-upload.
///
/// Chrome deliberately matches [NewConversationScreen] — same app bar, field
/// and footer-button treatment — so the two messenger modals read as one.
class ConvertToIncidentScreen extends StatefulWidget {
  const ConvertToIncidentScreen({
    super.key,
    required this.controller,
    required this.message,
  });

  final ConversationController controller;
  final Message message;

  @override
  State<ConvertToIncidentScreen> createState() => _ConvertToIncidentScreenState();
}

class _ConvertToIncidentScreenState extends State<ConvertToIncidentScreen> {
  final _description = TextEditingController();
  final _comment = TextEditingController();
  final _picker = ImagePicker();

  List<Coefficient> _priorities = const [];
  List<Departement> _departements = const [];
  Coefficient? _priority;
  Departement? _departement;

  /// Set when the message's sender has no single fixed store (an admin or area
  /// manager): the incident then needs a store chosen explicitly, or the server
  /// rejects the convert with "BoutiqueRequired".
  bool _requiresBoutique = false;
  List<BoutiqueOption> _boutiques = const [];
  BoutiqueOption? _boutique;

  /// A photo the user attached here, replacing the message's own image.
  XFile? _pickedImage;

  bool _isLoadingOptions = true;
  bool _hasLoadError = false;
  bool _cannotConvert = false;
  bool _isSubmitting = false;
  String? _submitError;

  bool get _isVoice => widget.message.type == MessageType.voice;

  /// The message's own image attachment, reused as evidence when the user picks
  /// nothing. Its `url` is the authorized content route, so it renders through
  /// [AuthImage] rather than Image.network.
  MessageAttachment? get _messageImage {
    for (final a in widget.message.attachments) {
      if (a.kind == AttachmentKind.image) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Seed the description from the message itself — the whole point of
    // converting rather than re-declaring. A voice note has no text to seed
    // with, so it stays empty and the form asks for a transcription instead.
    _description.text = (widget.message.body ?? '').trim();
    _loadOptions();
  }

  @override
  void dispose() {
    _description.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _hasLoadError = false;
    });
    try {
      final results = await Future.wait([
        IncidentService().getAllCoefficients(),
        MissionService().getDepartements(),
        widget.controller.getConvertOptions(widget.message.id),
      ]);
      if (!mounted) return;
      final convertOptions = results[2] as ConvertToIncidentOptions;
      // The server is the authority on who may convert what — surface a refusal
      // here rather than letting the submit fail.
      if (!convertOptions.canConvert) {
        setState(() {
          _isLoadingOptions = false;
          _cannotConvert = true;
        });
        return;
      }
      setState(() {
        _priorities = results[0] as List<Coefficient>;
        _departements = results[1] as List<Departement>;
        _requiresBoutique = convertOptions.requiresBoutiqueSelection;
        _boutiques = convertOptions.boutiques;
        // One choice is no choice — preselect it rather than making the user pick.
        _boutique = convertOptions.boutiques.length == 1
            ? convertOptions.boutiques.first
            : null;
        _isLoadingOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingOptions = false;
        _hasLoadError = true;
      });
    }
  }

  bool get _canSubmit =>
      _description.text.trim().isNotEmpty &&
      _comment.text.trim().isNotEmpty &&
      _priority != null &&
      _departement != null &&
      (!_requiresBoutique || _boutique != null) &&
      !_isSubmitting;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null || !mounted) return;
      setState(() => _pickedImage = picked);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Could not open the image');
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // Only a newly picked photo needs uploading; the message's existing
      // attachment is already on the server and is reused server-side.
      String? imageName;
      if (_pickedImage != null) {
        imageName = await MissionService().uploadFile(File(_pickedImage!.path));
      }

      final summary = await widget.controller.convertToIncident(
        widget.message,
        description: _description.text.trim(),
        commentaire: _comment.text.trim(),
        coefId: _priority!.coefId,
        departementId: _departement!.id,
        boutiqueId: _requiresBoutique ? _boutique!.id : null,
        problemImageBefore: imageName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = _readableError(e);
      });
    }
  }

  /// Surfaces the backend's own reason (BoutiqueRequired, NotAConversationMember…)
  /// rather than a blanket failure — those are actionable, a generic one isn't.
  String _readableError(Object e) {
    final raw = e.toString();
    if (raw.contains('BoutiqueRequired')) {
      return 'This message has no store attached, so an incident cannot be raised from it.';
    }
    if (raw.contains('CanOnlyConvertOwnMessages')) {
      return 'You can only convert your own messages.';
    }
    if (raw.contains('BoutiqueNotSupervised')) {
      return "You don't supervise this message's store.";
    }
    if (raw.contains('MessageDeleted')) {
      return 'This message was deleted.';
    }
    if (raw.contains('CannotConvertSystemMessage')) {
      return 'System messages cannot be converted.';
    }
    return 'Could not create the incident';
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
          'Convert to incident',
          style: TextStyle(color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator(color: CommColors.blue))
          : _cannotConvert
              ? _cannotConvertState()
              : _hasLoadError
                  ? _loadErrorState()
                  : _form(),
      bottomNavigationBar:
          _isLoadingOptions || _hasLoadError || _cannotConvert ? null : _footer(),
    );
  }

  Widget _cannotConvertState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.block, size: 36, color: CommColors.line),
            SizedBox(height: 10),
            Text(
              'This message cannot be converted into an incident.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CommColors.muted, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 36, color: CommColors.line),
            const SizedBox(height: 10),
            const Text(
              "Couldn't load priorities and departments",
              textAlign: TextAlign.center,
              style: TextStyle(color: CommColors.muted, fontSize: 13.5),
            ),
            TextButton(onPressed: _loadOptions, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _sourceBanner(),
        if (_isVoice) ...[
          const SizedBox(height: 10),
          _voiceHint(),
        ],
        const SizedBox(height: 16),
        if (_requiresBoutique) ...[
          _label('Store'),
          _boutiqueDropdown(),
          const SizedBox(height: 14),
        ],
        _label('Description'),
        _textField(
          controller: _description,
          hint: _isVoice
              ? 'Type what the voice message says'
              : 'What happened?',
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        _label('Comment'),
        _textField(
          controller: _comment,
          hint: 'Add context, next steps, who was notified…',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _label('Priority'),
        _priorityDropdown(),
        const SizedBox(height: 14),
        _label('Department'),
        _departementDropdown(),
        const SizedBox(height: 14),
        _label('Photo'),
        _photoField(),
        if (_submitError != null) ...[
          const SizedBox(height: 14),
          _errorBanner(),
        ],
      ],
    );
  }

  /// Shows which message is being converted, so the user can tell at a glance
  /// that the description below was pre-filled from it.
  Widget _sourceBanner() {
    final body = (widget.message.body ?? '').trim();
    final icon = switch (widget.message.type) {
      MessageType.image => Icons.image_outlined,
      MessageType.voice => Icons.mic_none,
      MessageType.file => Icons.attach_file,
      _ => Icons.forum_outlined,
    };
    final caption = switch (widget.message.type) {
      MessageType.image => 'Message image',
      MessageType.voice => 'Message vocal',
      MessageType.file => 'Message fichier',
      _ => 'Message',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CommColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CommColors.blueDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CommColors.blueDark,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: CommColors.ink2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A voice note carries no text the incident can inherit, so the user has to
  /// write the content themselves — saying so up front beats an empty field.
  Widget _voiceHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This is a voice message, so there is no text to copy over. '
              'Please listen to it and write its content in the description.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: CommColors.ink2,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  /// Tappable field that opens a searchable store list — supervisors can have dozens
  /// of stores, which a plain dropdown makes painful to scroll through.
  Widget _boutiqueDropdown() {
    final selected = _boutique;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickBoutique,
      child: InputDecorator(
        decoration: _inputDecoration('Select a store').copyWith(
          suffixIcon: const Icon(Icons.keyboard_arrow_down, color: CommColors.muted2),
        ),
        isEmpty: selected == null,
        child: selected == null
            ? null
            : _BoutiqueLabel(option: selected),
      ),
    );
  }

  Future<void> _pickBoutique() async {
    final picked = await showModalBottomSheet<BoutiqueOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BoutiqueSearchSheet(options: _boutiques, selectedId: _boutique?.id),
    );
    if (picked != null && mounted) {
      setState(() => _boutique = picked);
    }
  }

  Widget _priorityDropdown() {
    return DropdownButtonFormField<Coefficient>(
      value: _priority,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: CommColors.muted2),
      style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
      decoration: _inputDecoration('Select a priority'),
      items: _priorities
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.libelle ?? 'Priority ${c.coefId}'),
              ))
          .toList(),
      onChanged: (v) => setState(() => _priority = v),
    );
  }

  Widget _departementDropdown() {
    return DropdownButtonFormField<Departement>(
      value: _departement,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: CommColors.muted2),
      style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
      decoration: _inputDecoration('Select a department'),
      items: _departements
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.code ?? ''} - ${d.libelle ?? ''}'.trim()),
              ))
          .toList(),
      onChanged: (v) => setState(() => _departement = v),
    );
  }

  Widget _photoField() {
    // An image message already supplies its own evidence photo; anything the
    // user picks here replaces it.
    final inheritedImage = _messageImage;

    if (_pickedImage != null) {
      return _photoPreview(
        child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
        caption: 'Attached photo',
        onRemove: () => setState(() => _pickedImage = null),
      );
    }

    if (inheritedImage != null) {
      return _photoPreview(
        child: AuthImage(attachment: inheritedImage, width: 56, height: 56),
        caption: "From the message — used as the incident's photo",
        onRemove: null,
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            style: _pickerButtonStyle(),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined, size: 18),
            style: _pickerButtonStyle(),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }

  ButtonStyle _pickerButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: CommColors.blueDark,
      backgroundColor: CommColors.bgSoft,
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: const BorderSide(color: CommColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
    );
  }

  Widget _photoPreview({
    required Widget child,
    required String caption,
    required VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CommColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CommColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: child,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              caption,
              style: const TextStyle(fontSize: 12.5, color: CommColors.muted),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18, color: CommColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
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

  Widget _footer() {
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
            onPressed: _canSubmit ? _submit : null,
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
                    'Create incident',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Code chip + store name, used in the field and in each list row.
class _BoutiqueLabel extends StatelessWidget {
  final BoutiqueOption option;
  const _BoutiqueLabel({required this.option});

  @override
  Widget build(BuildContext context) {
    final code = option.code;
    return Row(
      children: [
        if (code != null && code.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: CommColors.line2, borderRadius: BorderRadius.circular(6)),
            child: Text(code, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: CommColors.muted)),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(option.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, color: CommColors.ink2)),
        ),
      ],
    );
  }
}

/// Bottom sheet: search box + filtered list, matching the store name or code while
/// ignoring case and accents ("hotel" finds "Hôtel", "bs" finds code "BS01").
class _BoutiqueSearchSheet extends StatefulWidget {
  final List<BoutiqueOption> options;
  final int? selectedId;
  const _BoutiqueSearchSheet({required this.options, this.selectedId});

  @override
  State<_BoutiqueSearchSheet> createState() => _BoutiqueSearchSheetState();
}

class _BoutiqueSearchSheetState extends State<_BoutiqueSearchSheet> {
  String _query = '';

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ÿ': 'y', 'ñ': 'n',
  };

  static String _normalize(String? value) {
    final lower = (value ?? '').toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      buffer.write(_accents[ch] ?? ch);
    }
    return buffer.toString();
  }

  List<BoutiqueOption> get _filtered {
    final needle = _normalize(_query).trim();
    if (needle.isEmpty) return widget.options;
    return widget.options
        .where((b) => _normalize(b.libelle).contains(needle) || _normalize(b.code).contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Padding(
      // Keep the search box above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: CommColors.line, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search a store by name or code',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('No store found', style: TextStyle(color: CommColors.muted)),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final b = results[i];
                        final isSelected = b.id == widget.selectedId;
                        return ListTile(
                          title: _BoutiqueLabel(option: b),
                          trailing: isSelected ? const Icon(Icons.check, color: CommColors.blue) : null,
                          onTap: () => Navigator.of(context).pop(b),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
