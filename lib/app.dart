import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:supervisormobile/features/VisualMerchandising/campaign_screen.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/onboarding.dart';
import 'package:supervisormobile/features/notifications/notification_controller.dart';
import 'package:supervisormobile/navigation_menu.dart';
import 'package:supervisormobile/services/PushNotificationService.dart';
import 'package:supervisormobile/services/SignalrNotificationService.dart';
import 'package:supervisormobile/utils/Keys/navigation_key.dart';
import 'package:supervisormobile/utils/theme/theme.dart';
import 'package:supervisormobile/controllers/language_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isFirstLaunch = true;
  bool _hasStoredData = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize language controller (app-wide, must survive logout/route cleanup)
    Get.put(LanguageController(), permanent: true);
    PushNotificationService.instance.onNotificationTap = _openCampaignsFromNotification;
    _checkLaunchStatus();
  }

  void _openCampaignsFromNotification(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const CampaignScreen()),
      (route) => route.isFirst,
    );
  }

  /// Shown when a SignalR event arrives while the app is already open, on top
  /// of whatever screen is currently visible (Get.snackbar doesn't need a
  /// local BuildContext, so this works regardless of the active route).
  void _showInAppToast(Map<String, dynamic> payload) {
    final title = payload['title']?.toString() ?? '';
    final body = payload['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final isRejection = payload['type']?.toString() == 'ExecutionRejected';

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isRejection ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.fromLTRB(12, 24, 12, 0),
      borderRadius: 12,
      maxWidth: 480,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      icon: Icon(
        isRejection ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      onTap: (_) => _openCampaignsFromNotification(payload),
    );
  }

  Future<void> _checkLaunchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = await _secureStorage.read(key: 'currentUserId');

      if (mounted) {
        setState(() {
          _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
          _hasStoredData = storedData != null;
          _isInitialized = true;
        });
      }

      if (_isFirstLaunch) {
        await prefs.setBool('isFirstLaunch', false);
      }

      if (storedData != null) {
        await PushNotificationService.instance.initialize();
        final notificationController = Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController(), permanent: true);
        SignalrNotificationService.instance.onNotificationReceived = (payload) {
          PushNotificationService.instance.showLocalNotificationFromSignalr(payload);
          notificationController.onRealtimeNotificationReceived();
          _showInAppToast(payload);
        };
        await SignalrNotificationService.instance.connect();
        await PushNotificationService.instance.registerDeviceToken();
      }
    } catch (e) {
      // Si la lecture du secure storage échoue (corruption/chiffrement),
      // vider complètement le stockage sécurisé et forcer la déconnexion
      try {
        await _secureStorage.deleteAll();
        print('Secure storage cleared due to error: $e');
      } catch (_) {
        // Ignorer les erreurs de suppression
      }

      if (mounted) {
        setState(() {
          _isFirstLaunch = false;
          _hasStoredData = false;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (languageController) => GetMaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('fr', ''),
        ],
        locale: languageController.currentLocale,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          // Set up overlay state as soon as the context is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Overlay setup removed - no longer needed
          });

          // Show loading while initializing
          if (!_isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return SafeArea(
            child: _isFirstLaunch
                ? const OnBoardingScreen()
                : _hasStoredData
                ? const NavigationMenu()
                : const LoginScreen(),
          );
        },
      ),
      ),
    );
  }
}

class DateExceededApp extends StatelessWidget {
  const DateExceededApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'This application is no longer available.',
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
