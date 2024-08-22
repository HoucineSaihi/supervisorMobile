import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/Profile/screens/profileScreen.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/features/incidents/screens/all_incidents_widget.dart';
import 'package:supervisormobile/features/notifications/screens/notifications.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
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
              indicatorColor: darkMode ? TColors.white.withOpacity(0.1) : TColors.black.withOpacity(0.1),

              destinations: const [
            NavigationDestination(icon: Icon(Iconsax.calendar), label: 'Calendrier'),
            NavigationDestination(icon: Icon(Iconsax.task), label: 'Incidents'),
            NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
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
    ProfileInfo(),
  ];

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}
