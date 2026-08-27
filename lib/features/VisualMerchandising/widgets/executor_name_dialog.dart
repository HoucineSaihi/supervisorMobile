import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Asks for the name of the person executing a campaign.
///
/// Shown once when a campaign is started, and again from the pen button next to
/// the name on the execution screen. Returns the trimmed name, or null when the
/// user dismisses the dialog.
class ExecutorNameDialog extends StatefulWidget {
  /// Pre-fills the field; non-empty when editing an already recorded name.
  final String initialName;

  /// Switches the copy between "start the campaign" and "edit the name".
  final bool isEditing;

  const ExecutorNameDialog({
    super.key,
    this.initialName = '',
    this.isEditing = false,
  });

  /// Opens the dialog. Not dismissible when naming for the first time, so a
  /// campaign never starts without an executor on record.
  static Future<String?> show(
    BuildContext context, {
    String initialName = '',
    bool isEditing = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: isEditing,
      builder: (_) => ExecutorNameDialog(
        initialName: initialName,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<ExecutorNameDialog> createState() => _ExecutorNameDialogState();
}

class _ExecutorNameDialogState extends State<ExecutorNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  final FocusNode _focusNode = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.vmExecutorRequiredError;
      });
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1E5FAA),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isEditing
                        ? l10n.vmExecutorEditDialogTitle
                        : l10n.vmExecutorDialogTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14315C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.vmExecutorDialogSubtitle,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF6B7F99),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.vmExecutorFieldLabel,
                hintText: l10n.vmExecutorFieldHint,
                errorText: _error,
                filled: true,
                fillColor: const Color(0xFFF6F9FD),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD7E5F3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD7E5F3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E5FAA)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancelling is only offered when editing: the first naming is
                // part of starting the campaign and cannot be skipped.
                if (widget.isEditing)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: Color(0xFF6B7F99)),
                    ),
                  ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5FAA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isEditing
                        ? l10n.vmExecutorSave
                        : l10n.vmExecutorConfirm,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
