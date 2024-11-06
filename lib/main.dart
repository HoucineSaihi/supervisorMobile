import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for SystemChrome
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/app.dart';

import 'utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'config.env');

  // Check if the date is beyond the allowed limit
  final currentDate = DateTime.now();
  final cutoffDate = DateTime(2024, 11, 15); // November 15, 2024

  if (currentDate.isAfter(cutoffDate)) {
    runApp(const DateExceededApp());
  } else {
    runApp(const App());
  }
}
