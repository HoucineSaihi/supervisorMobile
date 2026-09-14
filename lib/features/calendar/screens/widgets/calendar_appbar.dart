import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_icons/cart_notif_icon.dart';
import 'package:supervisormobile/features/notifications/notification_controller.dart';
import 'package:supervisormobile/features/notifications/screens/notifications.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class THomeAppBar extends StatefulWidget {
  const THomeAppBar({super.key});

  @override
  _THomeAppBarState createState() => _THomeAppBarState();
}

class _THomeAppBarState extends State<THomeAppBar> {
  final _storage = FlutterSecureStorage();
  String _currentUserName = '';
  late final NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _loadAuthToken(); // Load the token when the widget is initialized
    _notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);
    _notificationController.loadNotifications();
  }

  Future<void> _loadAuthToken() async {
    // Retrieve the token from secure storage
    String? token = await _storage.read(key: 'currentName');
    setState(() {
      _currentUserName = token ?? AppLocalizations.of(context)!.noTokenFound;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.welcome,
            style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.grey),
          ),
          Text(
            _currentUserName,
            style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
          ),
        ],
      ),
      actions: [
        Obx(() => TCartCounterIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              iconColor: TColors.white,
              unreadCount: _notificationController.unreadCount.value,
            )),
      ],
    );
  }
}
