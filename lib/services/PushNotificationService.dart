import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supervisormobile/services/DioService.dart';
import 'package:supervisormobile/services/SignalrNotificationService.dart';

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

/// The channel/sound id must match, byte for byte, the "vm_execution_notifications"
/// identifier the backend sends in the FCM payload's android.notification.channel_id
/// and apns.payload.aps.sound (as "vm_execution_notifications.caf") - see
/// NotificationDispatchService.cs on the backend.
const String _notificationChannelId = 'vm_execution_notifications';

/// Must be a top-level function (FCM requirement) so it can run in a
/// background isolate when the app is terminated or backgrounded.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS displays the notification automatically from the payload's
  // `notification` block + the Android channel's sound when the app isn't in
  // the foreground - nothing to do here beyond letting FCM/the OS handle it.
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? onNotificationTap;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Same missing-custom-sound fallback as _showLocalNotification: Android
    // pins a channel's sound permanently once created, so if the raw resource
    // is missing at channel-creation time we must not reference it here either.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _notificationChannelId,
        'Notifications d\'exécution VM',
        description: 'Notifications de soumission et de refus d\'exécution.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound(_notificationChannelId),
      ));
    } catch (e) {
      print('⚠️ PushNotificationService: could not create channel with custom sound, using default: $e');
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _notificationChannelId,
        'Notifications d\'exécution VM',
        description: 'Notifications de soumission et de refus d\'exécution.',
        importance: Importance.max,
      ));
    }

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = Map<String, dynamic>.from(jsonDecode(payload));
        onNotificationTap?.call(data);
      },
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      // While the app is foregrounded, the SignalR hub already delivers this
      // same event (usually first) and shows it via showLocalNotificationFromSignalr.
      // Skip the FCM foreground display entirely to avoid a duplicate - FCM's
      // OS-level display is only actually needed when backgrounded/terminated,
      // which this listener never runs for anyway.
      if (SignalrNotificationService.instance.isConnected) return;
      _showLocalNotification(
        id: _notificationId(message.data),
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }

    _messaging.onTokenRefresh.listen((_) => registerDeviceToken());
  }

  /// Shows a local notification for an event received over the SignalR hub
  /// while the app is in the foreground (SignalR has no OS-level display of
  /// its own, unlike FCM's background/terminated path).
  Future<void> showLocalNotificationFromSignalr(Map<String, dynamic> payload) async {
    final title = payload['title']?.toString() ?? '';
    final body = payload['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final data = payload.map((key, value) => MapEntry(key, value?.toString() ?? ''));
    await _showLocalNotification(
      id: _notificationId(data),
      title: title,
      body: body,
      data: data,
    );
  }

  /// The backend's Notification.Id, shared by both the FCM payload's `data`
  /// block and the SignalR broadcast - using it as the local notification id
  /// means whichever transport arrives second replaces the first instead of
  /// stacking a duplicate OS notification for the same event.
  int _notificationId(Map<String, dynamic> data) {
    final rawId = data['id'];
    final parsed = int.tryParse(rawId?.toString() ?? '');
    return parsed ?? data.hashCode;
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // The custom sound file (android/app/src/main/res/raw/vm_execution_notifications.*
    // and ios/Runner/vm_execution_notifications.caf) is a placeholder pending a real
    // asset - fall back to the platform default sound rather than dropping the
    // notification (and the badge/refresh logic chained after it) entirely.
    try {
      await _showLocalNotificationWithSound(
        id: id,
        title: title,
        body: body,
        data: data,
        useCustomSound: true,
      );
    } catch (e) {
      print('⚠️ PushNotificationService: custom notification sound unavailable, falling back to default: $e');
      await _showLocalNotificationWithSound(
        id: id,
        title: title,
        body: body,
        data: data,
        useCustomSound: false,
      );
    }
  }

  Future<void> _showLocalNotificationWithSound({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required bool useCustomSound,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          'Notifications d\'exécution VM',
          channelDescription: 'Notifications de soumission et de refus d\'exécution.',
          importance: Importance.max,
          priority: Priority.high,
          sound: useCustomSound
              ? const RawResourceAndroidNotificationSound(_notificationChannelId)
              : null,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(
          sound: useCustomSound ? '$_notificationChannelId.caf' : null,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> registerDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final platform = _currentPlatform();
      await DioService.dio.post('/DeviceToken', data: {
        'token': token,
        'platform': platform,
      });
    } catch (e) {
      print('❌ PushNotificationService: failed to register device token: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await DioService.dio.post('/DeviceToken/unregister', data: {
        'token': token,
      });
    } catch (e) {
      print('❌ PushNotificationService: failed to unregister device token: $e');
    }
  }

  String _currentPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'unknown';
    }
  }
}
