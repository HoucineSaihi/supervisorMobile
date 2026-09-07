# Notification sound asset needed here

Drop the custom notification sound file at:

    android/app/src/main/res/raw/vm_execution_notifications.mp3

(or `.wav` / `.ogg` — any format Android's `MediaPlayer` supports). The filename
(without extension) must stay exactly `vm_execution_notifications` since it is
referenced by id from `lib/services/PushNotificationService.dart`
(`_notificationChannelId`) and from the backend's FCM payload
(`NotificationDispatchService.cs`, `AndroidNotification.Sound`).

Until a real file is added here, Android will silently fall back to the
device's default notification sound instead of throwing an error — the
channel is still created correctly either way.

The matching iOS sound file goes at `ios/Runner/vm_execution_notifications.caf`
(see the note left in that folder).
