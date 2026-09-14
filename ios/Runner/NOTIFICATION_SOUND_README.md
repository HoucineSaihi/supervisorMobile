# iOS notification sound + required Xcode steps

Two things need to happen in Xcode (not achievable by editing files alone) before
push notifications work on a real iOS build:

1. **Add the Runner.entitlements file to the Xcode project and enable the "Push
   Notifications" capability.** `ios/Runner/Runner.entitlements` has already been
   created with `aps-environment: development` (switch to `production` for release
   builds/TestFlight/App Store). Open `ios/Runner.xcworkspace` in Xcode, select the
   Runner target > Signing & Capabilities > "+ Capability" > "Push Notifications" -
   Xcode will link the entitlements file and set `CODE_SIGN_ENTITLEMENTS`
   automatically in the project settings.

2. **Add the custom notification sound file** at `ios/Runner/vm_execution_notifications.caf`
   (Apple requires `.caf`, `.aiff`, or `.wav`, under 30 seconds) via Xcode's
   "Add Files to Runner..." so it's bundled into the app target. The filename
   (without extension) must stay exactly `vm_execution_notifications` - it's
   referenced by id from `lib/services/PushNotificationService.dart` and the
   backend's `NotificationDispatchService.cs` (`Apns.Aps.Sound`).

Until the sound file is added, iOS will fall back to the default notification
sound - it will not crash or throw.

APNs also requires an authentication key (or certificate) generated in the Apple
Developer portal and uploaded to the Firebase console's Cloud Messaging project
settings - without it, FCM cannot deliver to iOS devices at all (Android is
unaffected and will work without this step).
