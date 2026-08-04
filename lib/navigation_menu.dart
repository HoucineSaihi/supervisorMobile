import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/Profile/screens/profileScreen.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/features/incidents/screens/all_incidents_widget.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'features/VisualMerchandising/campaign_screen.dart';
import 'features/communication/controllers/messenger_controller.dart';
import 'features/communication/screens/conversations_list_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    // Bring the realtime channel up once for the whole app, so notifications arrive
    // on any tab — not only while the Messages tab is open. Permanent so it survives
    // tab switches and owns the single shared SignalR connection.
    //
    // Guarded by isRegistered: build() re-runs on every tab tap (the bar below is
    // wrapped in Obx), and `Get.put(MessengerController())` would construct a fresh
    // controller each time. GetX discards the duplicate without ever calling its
    // onInit, so the throwaway instance's streams leak and no load ever fires.
    if (!Get.isRegistered<MessengerController>()) {
      Get.put(MessengerController(), permanent: true);
    }
    final messenger = Get.find<MessengerController>();
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

            // ── Smart Messenger (Phase G) ────────────────
            NavigationDestination(
              icon: Obx(() => _MessagesIcon(unread: messenger.unreadNotifications.value)),
              label: 'Messages',
            ),

            NavigationDestination(
              icon: const Icon(Iconsax.user),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
      // The message toast is mounted app-globally (see GetMaterialApp.builder in
      // app.dart) so it shows on every route, not just these tabs.
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

/// Message-tab icon with an unread badge overlaid in the corner.
class _MessagesIcon extends StatelessWidget {
  final int unread;
  const _MessagesIcon({required this.unread});

  @override
  Widget build(BuildContext context) {
    if (unread <= 0) return const Icon(Iconsax.message);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Iconsax.message),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;

  /// Index of the Smart Messenger destination in [screens].
  static const int messagesTabIndex = 3;

  final List<Widget> screens = [
    const CalendarPlanning(),
    AllIncidentsWidget(),
    const CampaignScreen(), // ← nouveau
    const ConversationsListScreen(), // ← Smart Messenger
    ProfileInfo(),
  ];

  void changeIndex(int index) {
    selectedIndex.value = index;
    // The messenger controller is permanent, so ConversationsListScreen is not
    // rebuilt from scratch on tab entry and would otherwise show whatever the
    // single startup load left behind — including nothing, if that load failed.
    // Refresh silently so the existing list stays visible while it revalidates.
    if (index == messagesTabIndex && Get.isRegistered<MessengerController>()) {
      Get.find<MessengerController>().loadConversations(silent: true);
    }
  }
}