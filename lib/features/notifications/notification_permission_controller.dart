import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/notifications/widgets/notification_permission_sheets.dart';
import 'package:supervisormobile/services/NotificationPermissionService.dart';
import 'package:supervisormobile/services/PushNotificationService.dart';

/// Tracks whether the OS lets this app show notifications, and drives the
/// "turn them on" prompts. Not being able to deliver a notification is silent
/// for the user, so the app has to notice and say so.
class NotificationPermissionController extends GetxController
    with WidgetsBindingObserver {
  static const _lastPromptKey = 'notifPermissionLastPromptAtMs';

  /// How long to leave the user alone after the auto-prompt was shown. The
  /// banner and the bell indicator stay visible in the meantime.
  static const _promptCooldown = Duration(days: 3);

  /// Optimistic until the first check completes, so a user who has notifications
  /// on never sees the warning flash up at startup.
  final RxBool isEnabled = true.obs;

  bool _promptedThisSession = false;

  /// The controller is created lazily by whichever widget needs it first, and
  /// outlives route changes (see the same pattern for NotificationController).
  static NotificationPermissionController ensure() =>
      Get.isRegistered<NotificationPermissionController>()
          ? Get.find<NotificationPermissionController>()
          : Get.put(NotificationPermissionController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshStatus();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Coming back from the system settings (or the permission dialog) is the only
  /// moment the answer can have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshStatus();
  }

  Future<void> refreshStatus() async {
    final wasEnabled = isEnabled.value;
    isEnabled.value = await NotificationPermissionService.instance.isEnabled();
    if (!wasEnabled && isEnabled.value) {
      // The token may have been left unregistered while notifications were off
      // (iOS only hands one out once the user has allowed them).
      PushNotificationService.instance.registerDeviceToken();
    }
  }

  /// One tap from the banner: ask the OS if it will still show its dialog,
  /// otherwise walk the user through the system settings.
  Future<void> enable(BuildContext context) async {
    await NotificationPermissionService.instance.request();
    await refreshStatus();
    if (!context.mounted) return;
    if (isEnabled.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notifPermEnabledToast)),
      );
      return;
    }
    await showNotificationSettingsGuide(context);
  }

  /// Offers to turn notifications on if they're off, at most once per session and
  /// once per [_promptCooldown]. Safe to call every time the home screen builds.
  Future<void> promptIfNeeded(BuildContext context) async {
    if (_promptedThisSession) return;
    _promptedThisSession = true;

    await refreshStatus();
    if (isEnabled.value) return;

    final prefs = await SharedPreferences.getInstance();
    final lastPrompt = prefs.getInt(_lastPromptKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastPrompt != null && now - lastPrompt < _promptCooldown.inMilliseconds) {
      return;
    }
    if (!context.mounted) return;

    await prefs.setInt(_lastPromptKey, now);
    if (!context.mounted) return;
    final accepted = await showNotificationPermissionPrompt(context);
    if (accepted == true && context.mounted) {
      await enable(context);
    }
  }
}
