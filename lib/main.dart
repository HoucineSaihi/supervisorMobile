import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';
import 'package:supervisormobile/services/DioService.dart';

import 'utils/theme/theme.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
 await dotenv.load(fileName: 'config.env');
  
  // Initialize DioService and loading manager
  DioService.initialize();
  
  runApp(const App());
}



