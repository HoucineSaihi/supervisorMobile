import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/onboarding.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/navigation_menu.dart';
import 'package:supervisormobile/utils/Keys/navigation_key.dart';
import 'package:supervisormobile/utils/theme/theme.dart';
import 'package:supervisormobile/Interceptors/loading_interceptor.dart';

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
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
        Locale('fr', ''),
      ],
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          // Set up overlay state as soon as the context is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final overlay = Overlay.of(context);
            if (overlay != null) {
              LoadingInterceptor.setOverlayState(overlay);
              print('✅ App: Overlay state set successfully');
            } else {
              print('❌ App: Failed to get overlay state');
            }
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
