import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supervisormobile/api/firebase_api.dart';
import 'package:supervisormobile/app.dart';

import 'utils/theme/theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAwYrlq_b1rLB22s_3mz5sq4r39Z8Zd4pI",
      appId: "1:1027875327523:android:f9203e83ba4fffeb91eb96",
      messagingSenderId: "1027875327523",
      projectId: "supervisor-16960",
      storageBucket: "supervisor-16960.firebasestorage.app",
    ),
  );
  await FirebaseApi().initNotifications();
 await dotenv.load(fileName: 'config.env');
  runApp(const App());
}



