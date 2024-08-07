import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/navigation_menu.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/TImages.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/utils/constants/sizes.dart';

class  LoginScreen extends StatelessWidget {
  const LoginScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: 56.0,
            left: TSizes.defaultSpace,
            bottom: TSizes.defaultSpace,
            right:TSizes.defaultSpace,

          ), child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image(height: 150,
                image: AssetImage(dark ? TImages.lightAppLogo : TImages.darkAppLogo),
                ),
                Text("SuperVisor",style: Theme.of(context).textTheme.headlineMedium,),
                const SizedBox(height: 16.0,),
                Text("Organisez et suivez vos missions en toute simplicité avec notre application dédiée.",style: Theme.of(context).textTheme.bodyMedium,)
              ],

            ),
            Form(child: Padding(
              padding: const EdgeInsets.symmetric(vertical : 32.0),
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(prefixIcon: Icon(Iconsax.direct_right),labelText: "Saisir votre username"),
                  ),
                  const SizedBox(height: 16.0,),
                  TextFormField(
                    decoration: InputDecoration(prefixIcon: Icon(Iconsax.password_check),labelText: "Saisir votre mot de passe", suffixIcon:  Icon(Iconsax.eye_slash)),
                  ),
                  const SizedBox(height: 16.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(value: true, onChanged : (value){}),
                          const Text("Mémoriser")
                        ],
                      ),
                      TextButton(onPressed: (){}, child: const Text("Mot de passe oubliée ?"))
                    ],
                  ),
                  SizedBox(width : double.infinity,child: ElevatedButton(onPressed: (){
                    Get.to(() => NavigationMenu());
                  }, child : const Text("Se Connecter")),)
                ],
              ),
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Divider( color : dark? TColors.darkGrey : TColors.grey, thickness: 0.5, indent : 60, endIndent: 5 ,)
              ],
            )
          ],
        ),
        )
      )
    );
  }
}
