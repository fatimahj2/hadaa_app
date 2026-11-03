import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await notificationsPlugin.initialize(initSettings);
}

Future<void> showAlertNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'hadaa_alert_channel',
    'Hadaa Alerts',
    channelDescription: 'Panic alert notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);
  await notificationsPlugin.show(
    0,
    'تنبيه',
    'تم رصد مؤشرات مرتفعة، ابدئي التهدئة الآن',
    details,
  );
}

Future<void> requestNotificationPermission() async {
  final androidPlugin =
      notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
}
