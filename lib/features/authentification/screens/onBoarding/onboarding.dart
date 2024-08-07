import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/authentification/controllers.onboarding/onboarding_controller.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/widgets/OnBoardingNextButton.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/widgets/OnBoardingSkip.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/widgets/onboarding_dot_navigation.dart';
import 'package:supervisormobile/features/authentification/screens/onBoarding/widgets/onboarding_page.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/utils/constants/sizes.dart';
import 'package:supervisormobile/utils/device/device_utility.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children:  const [
                 OnBoardingWidget(
                  image : "lib/assets/on_boarding_images/welcomeImage.png",
                  title : "Bienvenue Dans SuperVisor",
                  subTitle: "Optimisez vos performances avec des fonctionnalités conçues pour les Area Managers.",

                ),
              OnBoardingWidget(
                image : "lib/assets/on_boarding_images/secondOnBoarding.png",
                title : "Gérer Vos Missions",
                subTitle: "Organisez et suivez vos missions en toute simplicité avec notre application dédiée.",

              )

            ],
          ),
          const OnBoardingSkip(),
          const OnBoardingDotNavigation(),
          const OnBoardingNextButton()


        ],
      ),
    );
  }
}






