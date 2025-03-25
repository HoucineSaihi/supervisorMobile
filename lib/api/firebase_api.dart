import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('title : ${message.notification?.title}');
  print('Body : ${message.notification?.body}');
  print('Payload : ${message.data}');

}
class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _storage = FlutterSecureStorage();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();

    print('Token : $fCMToken');
    await _storage.write(key: 'FCM', value: fCMToken);

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

}