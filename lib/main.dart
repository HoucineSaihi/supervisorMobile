import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';

import 'utils/theme/theme.dart';
import 'dart:html';
void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  window.localStorage.clear();
  runApp(const App());
}



