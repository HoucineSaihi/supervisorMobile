import 'package:flutter/material.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_icons/cart_notif_icon.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start ,
        children: [
          Text("Bienvenue", style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.grey)),
          Text("Houcine SAIHI", style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white))

        ],
      ),
      actions: [
        TCartCounterIcon(onPressed: (){},iconColor: TColors.white,)
      ],
    );
  }
}