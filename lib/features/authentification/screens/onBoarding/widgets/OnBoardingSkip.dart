import 'package:flutter/material.dart';
import 'package:supervisormobile/features/authentification/controllers.onboarding/onboarding_controller.dart';
import 'package:supervisormobile/utils/constants/sizes.dart';
import 'package:supervisormobile/utils/device/device_utility.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(top:TDeviceUtils.getAppBarHeight(),
        right: TSizes.defaultSpace,
        child: TextButton(onPressed: ()=>OnBoardingController.instance.skipPage(),
            child: Text(AppLocalizations.of(context)!.skip) ));
  }
}