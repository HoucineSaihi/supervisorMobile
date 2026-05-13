import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';
import 'package:supervisormobile/services/AppVersionService.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'config.env');
  await AppVersionService.clearCacheIfUpdated();
  runApp(const App());
}



