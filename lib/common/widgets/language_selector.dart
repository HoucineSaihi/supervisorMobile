import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/controllers/language_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Falls back to registering the controller: this widget can be mounted from
    // any screen, and must not depend on another route having put it first.
    final languageController = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>()
        : Get.put(LanguageController(), permanent: true);

    return GetBuilder<LanguageController>(
      init: languageController,
      builder: (controller) => ListTile(
        leading: const Icon(Icons.language),
        title: Text(AppLocalizations.of(context)!.language),
        subtitle: Text(
          controller.isEnglish
            ? AppLocalizations.of(context)!.english
            : AppLocalizations.of(context)!.french
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showLanguageDialog(context, controller),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageController languageController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                title: Text(AppLocalizations.of(context)!.english),
                value: const Locale('en', ''),
                groupValue: languageController.currentLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    languageController.changeLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<Locale>(
                title: Text(AppLocalizations.of(context)!.french),
                value: const Locale('fr', ''),
                groupValue: languageController.currentLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    languageController.changeLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
