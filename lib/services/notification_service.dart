import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen((message) {
      print("📥 إشعار جديد: ${message.notification?.title}");
    });
  }
}
