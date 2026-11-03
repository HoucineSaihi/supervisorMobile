import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/services/NotificationPermissionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

/// Friendly "turn notifications on?" sheet. Resolves to true when the user
/// accepted, so the caller can go on to ask the OS.
Future<bool?> showNotificationPermissionPrompt(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return _SheetFrame(
        title: l10n.notifPermPromptTitle,
        children: [
          Text(l10n.notifPermPromptBody),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: Text(l10n.notifPermTurnOn),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: Text(l10n.notifPermNotNow),
          ),
        ],
      );
    },
  );
}

/// Shown when only the phone's settings can fix it (the OS won't show its own
/// dialog any more). Spells out the steps so nobody has to hunt for the switch.
Future<void> showNotificationSettingsGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return _SheetFrame(
        title: l10n.notifPermGuideTitle,
        children: [
          Text(l10n.notifPermGuideIntro),
          const SizedBox(height: 16),
          _Step(number: 1, text: l10n.notifPermGuideStep1),
          _Step(number: 2, text: l10n.notifPermGuideStep2),
          _Step(number: 3, text: l10n.notifPermGuideStep3),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await NotificationPermissionService.instance.openSettings();
            },
            child: Text(l10n.notifPermOpenSettings),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(l10n.notifPermNotNow),
          ),
        ],
      );
    },
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 44, color: TColors.warning),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: TColors.primary,
            child: Text(
              '$number',
              style: const TextStyle(
                  color: TColors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
