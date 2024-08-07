import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';

import 'utils/theme/theme.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
dotenv.load();
  runApp(const App());
}



