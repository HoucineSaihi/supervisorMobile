import 'package:flutter/material.dart';
import 'package:supervisormobile/app.dart';
import 'package:supervisormobile/services/DioService.dart';

import 'utils/theme/theme.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DioService and LoadingManager
  DioService.initialize();
  
  runApp(const App());
}



