import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/onboarding.dart';
import 'package:supervisormobile/navigation_menu.dart';
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
    // Initialize language controller
    Get.put(LanguageController());
    _checkLaunchStatus();
  }

  Future<void> _checkLaunchStatus() async {
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
