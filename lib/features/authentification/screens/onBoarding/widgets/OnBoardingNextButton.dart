import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/authentification/controllers.onboarding/onboarding_controller.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/utils/constants/sizes.dart';
import 'package:supervisormobile/utils/device/device_utility.dart';

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Positioned(
        right: TSizes.defaultSpace,
        bottom: TDeviceUtils.getBottomNavigationBarHeight(),
        child: ElevatedButton(
            onPressed: () => OnBoardingController.instance.nextPage(),
            style:ElevatedButton.styleFrom(shape:  CircleBorder(), backgroundColor: dark ? TColors.primary : Colors.black),
            child: const Icon(Iconsax.arrow_right_3)
        ));
  }
}