import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';

import 'utils/theme/theme.dart';
import 'dart:html';
void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  window.localStorage.clear();
 await dotenv.load(fileName: 'config.env');
  runApp(const App());
}



