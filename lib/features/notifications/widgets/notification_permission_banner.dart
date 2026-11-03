import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/notifications/notification_permission_controller.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

/// Warning strip that appears only while the OS is blocking notifications, with
/// a one-tap way to fix it. Collapses to nothing once they're back on - the
/// controller re-checks when the user returns from the system settings.
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationPermissionController.ensure();
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      if (controller.isEnabled.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TColors.warning.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_off_outlined, color: TColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notifPermBannerTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.notifPermBannerBody,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => controller.enable(context),
                      child: Text(l10n.notifPermTurnOn),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
