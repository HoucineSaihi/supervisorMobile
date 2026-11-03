package com.example.supervisormobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Must match NotificationPermissionService._channel on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "supervisormobile/notification_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens this app's notification page directly (one toggle away from "Allow
     * notifications"), instead of the generic App Info page where the user has to
     * find "Notifications" on their own. Falls back to App Info on devices that
     * can't resolve the notification intent. Returns false if neither could open.
     */
    private fun openNotificationSettings(): Boolean {
        val notificationIntent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            // Pre-Oreo (API 23-25) extras for the same screen.
            .putExtra("app_package", packageName)
            .putExtra("app_uid", applicationInfo.uid)
        val appDetailsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", packageName, null))

        for (intent in listOf(notificationIntent, appDetailsIntent)) {
            try {
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // try the next fallback
            }
        }
        return false
    }
}
