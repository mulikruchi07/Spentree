import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));

    const channel = AndroidNotificationChannel(
      'spend_alerts', 'Spending Alerts',
      description: 'Alerts when your daily spending exceeds your limit',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showOverspendAlert(double total, int limit) async {
    const androidDetails = AndroidNotificationDetails('spend_alerts', 'Spending Alerts', importance: Importance.high, priority: Priority.high);
    await _plugin.show(
      1001, "You've exceeded your daily limit",
      "Today's spending is Rs. ${total.toStringAsFixed(0)}, over your Rs. $limit limit.",
      const NotificationDetails(android: androidDetails),
    );
  }
}