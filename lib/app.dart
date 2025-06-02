import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/onboarding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisormobile/utils/navigation_key.dart';
import 'package:supervisormobile/utils/theme/theme.dart';

import 'features/calendar/screens/calendar.dart';
import 'navigation_menu.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isFirstLaunch = true;
  bool _hasStoredData = false;

  @override
  void initState() {
    super.initState();
    _checkLaunchStatus();
  }

  Future<void> _checkLaunchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = await _secureStorage.read(key: 'currentUserId'); // Replace 'some_key' with your specific key.

    setState(() {
      _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
      _hasStoredData = storedData != null; // Check if secureStorage has data.
    });

    if (_isFirstLaunch) {
      // Set it to false for future launches
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey, // ✅ ADD THIS LINE

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // English
        const Locale('ar', ''), // Arabic
        const Locale('fr', ''), // French
      ],
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: SafeArea(
        child: const LoginScreen()

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