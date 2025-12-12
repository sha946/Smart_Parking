import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initSettings);

    _initialized = true;
    print('✓ Notifications initialisées');
  }

  Future<void> showFreeSpotNotification({
    required String spotId,
    String? additionalInfo,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'parking_spots',
          'Places de Parking',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      spotId.hashCode,
      '🅿️ Place Disponible!',
      'La place $spotId est maintenant libre',
      details,
    );

    print('✓ Notification: $spotId');
  }
}
