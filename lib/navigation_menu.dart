import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/Profile/screens/profileScreen.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/features/incidents/screens/all_incidents_widget.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'features/VisualMerchandising/widgets/campaign_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Obx(
            () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.changeIndex(index),
          backgroundColor: darkMode ? TColors.black : TColors.white,
          indicatorColor: darkMode
              ? TColors.white.withOpacity(0.1)
              : TColors.black.withOpacity(0.1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Iconsax.calendar),
              label: AppLocalizations.of(context)!.calendar,
            ),
            NavigationDestination(
              icon: const Icon(Iconsax.task),
              label: AppLocalizations.of(context)!.incidents,
            ),

            // ── Nouveau : Campagnes ──────────────────────
            NavigationDestination(
              icon: const Icon(Iconsax.shopping_bag),  // icône VM
              label: AppLocalizations.of(context)!.campaigns,
            ),

            NavigationDestination(
              icon: const Icon(Iconsax.user),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
      body: Obx(
            () => controller.screens[controller.selectedIndex.value],
      ),
    );
  }
}

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;

  final List<Widget> screens = [
    const CalendarPlanning(),
    AllIncidentsWidget(),
    const CampaignScreen(), // ← nouveau
    ProfileInfo(),
  ];

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}