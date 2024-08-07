import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/onboarding.dart';
import 'package:supervisormobile/utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: const OnBoardingScreen(),
    );
  }
}


