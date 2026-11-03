import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

/// Reads / asks for the OS-level notification permission and sends the user to
/// the right system screen when it can only be fixed there.
///
/// The status comes from Firebase Messaging rather than permission_handler: the
/// app already depends on it for requesting the permission, it needs no iOS
/// Podfile flag, and on Android it also reflects notifications that were switched
/// off from the system settings (the only way to disable them below Android 13).
class NotificationPermissionService {
  NotificationPermissionService._();

  static final NotificationPermissionService instance =
      NotificationPermissionService._();

  /// Must match the channel registered in MainActivity.kt.
  static const MethodChannel _channel =
      MethodChannel('supervisormobile/notification_settings');

  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<bool> isEnabled() async {
    if (!_isSupported) return true;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return _isAuthorized(settings.authorizationStatus);
    } catch (e) {
      // A failed check must never nag the user about something that may be fine.
      print('⚠️ NotificationPermissionService: could not read status: $e');
      return true;
    }
  }

  /// Shows the system permission dialog when the OS still allows one (first ask,
  /// or Android 13+ after a single refusal). When it doesn't - iOS after a
  /// refusal, Android after two, or Android 12 and below where the permission is
  /// a settings switch - this returns the unchanged status without any dialog.
  Future<bool> request() async {
    if (!_isSupported) return true;
    try {
      final settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      return _isAuthorized(settings.authorizationStatus);
    } catch (e) {
      print('❌ NotificationPermissionService: permission request failed: $e');
      return false;
    }
  }

  /// Android: this app's notification page. iOS (and any Android failure):
  /// the app's page in Settings, which has the Notifications row.
  Future<void> openSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final opened = await _channel.invokeMethod<bool>('openNotificationSettings');
        if (opened == true) return;
      } catch (e) {
        print('⚠️ NotificationPermissionService: native settings intent failed: $e');
      }
    }
    await openAppSettings();
  }
}
