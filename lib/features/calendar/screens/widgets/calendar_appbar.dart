import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_icons/cart_notif_icon.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class THomeAppBar extends StatefulWidget {
  const THomeAppBar({super.key});

  @override
  _THomeAppBarState createState() => _THomeAppBarState();
}

class _THomeAppBarState extends State<THomeAppBar> {
  final _storage = FlutterSecureStorage();
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadAuthToken(); // Load the token when the widget is initialized
  }

  Future<void> _loadAuthToken() async {
    // Retrieve the token from secure storage
    String? token;

    if (kIsWeb) {
      // Use shared_preferences for web
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('currentName');
    } else {
      // Use flutter_secure_storage for mobile
      final _storage = FlutterSecureStorage();
      token = await _storage.read(key: 'currentName');
    }

    setState(() {
      _currentUserName = token ?? 'No token found';
    });
  }

  @override
  Widget build(BuildContext context) {
    return TAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bienvenue",
            style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.grey),
          ),
          Text(
            _currentUserName,
            style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
          ),
        ],
      ),
      actions: [
        TCartCounterIcon(
          onPressed: () {},
          iconColor: TColors.white,
        ),
      ],
    );
  }
}
