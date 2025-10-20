import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static LanguageController get instance => Get.find();
  
  final Rx<Locale> _currentLocale = const Locale('en', '').obs;
  Locale get currentLocale => _currentLocale.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code');
    final savedCountryCode = prefs.getString('country_code');
    
    if (savedLanguageCode != null) {
      _currentLocale.value = Locale(savedLanguageCode, savedCountryCode ?? '');
    }
  }
  
  Future<void> changeLanguage(Locale locale) async {
    _currentLocale.value = locale;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('country_code', locale.countryCode ?? '');
    
    // Update GetX locale and rebuild the app
    Get.updateLocale(locale);
    update(); // This will trigger GetBuilder to rebuild
  }
  
  bool get isEnglish => _currentLocale.value.languageCode == 'en';
  bool get isFrench => _currentLocale.value.languageCode == 'fr';
}
