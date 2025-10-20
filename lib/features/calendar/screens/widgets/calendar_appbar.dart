import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_icons/cart_notif_icon.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAuthToken(); // Load the token when the widget is initialized
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
        TCartCounterIcon(
          onPressed: () {},
          iconColor: TColors.white,
        ),
      ],
    );
  }
}
