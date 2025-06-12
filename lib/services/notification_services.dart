import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    await Permission.notification.request();
  }

  static Future<void> showNow({
    int id = 0,
    String title = 'Notifica CardWatch',
    String body = 'Hai una nuova notifica!',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> showDelayed({
    int id = 1,
    String title = 'Notifica CardWatch (ritardata)',
    String body = 'Hai una nuova notifica dopo 30 secondi!',
    Duration delay = const Duration(seconds: 30),
  }) async {
    await Future.delayed(delay);
    await showNow(id: id, title: title, body: body);
  }
}
