import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Permissions (iOS / Android 13+)
    await _messaging.requestPermission();

    // Token
    final token = await _messaging.getToken();
    print("FCM Token: $token");

    // Local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(initSettings);

    // Listener foreground
    FirebaseMessaging.onMessage.listen((message) {
      _localNotif.show(
        0,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'parking_channel',
            'Parking Notifications',
            importance: Importance.high,
          ),
        ),
      );
    });
  }
}
