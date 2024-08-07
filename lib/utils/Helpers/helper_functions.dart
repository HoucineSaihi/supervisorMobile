import 'package:flutter/material.dart';
import 'package:get/get.dart';

class THelperFunctions{


static bool isDarkMode(BuildContext context){
  return Theme.of(context).brightness == Brightness.dark;
}

  static void showSnackBar(String message){
    ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(message),)
    );

  }


  static void showAlert(String title , String message){
    showDialog(context: Get.context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ok'),
              )
            ],
          );
        });
  }


  static void navigateToScreen( BuildContext context , Widget screen) {
    Navigator.push(
        context,
        MaterialPageRoute(builder:(_) => screen)
    );
  }

  static Size screenSize(){
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight(){
    return MediaQuery.of(Get.context!).size.height;
  }


  static double screenWidth(){
    return MediaQuery.of(Get.context!).size.width;
  }
}