import 'package:flutter/material.dart';
import 'package:supervisormobile/app.dart';
import 'package:supervisormobile/services/DioService.dart';
import 'package:supervisormobile/utils/Helpers/robust_storage_service.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize RobustStorageService first
  await RobustStorageService.initialize();
  
  // Initialize DioService and LoadingManager
  DioService.initialize();
  
  runApp(const App());
}



