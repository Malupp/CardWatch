import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const CardWatchHomePage(title: 'CardWatch'),
    );
  }
}

class CardWatchHomePage extends StatefulWidget {
  const CardWatchHomePage({super.key, required this.title});

  final String title;

  @override
  State<CardWatchHomePage> createState() => _CardWatchHomePageState();
}

class _CardWatchHomePageState extends State<CardWatchHomePage> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  void _openNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Notifica CardWatch',
      'Hai una nuova notifica!',
      platformChannelSpecifics,
    );
  }

  void _openNotificationWithDelay() async {
    await Future.delayed(const Duration(seconds: 30));
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      1,
      'Notifica CardWatch (ritardata)',
      'Hai una nuova notifica dopo 30 secondi!',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ), // margine esterno (tutto intorno)
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 300, // larghezza massima del TextField
            ),
            child: TextField(),
          ),
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _openNotification,
            tooltip: 'Open Notifications',
            child: const Icon(Icons.notifications_active),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _openNotificationWithDelay,
            tooltip: 'Notifica dopo 30s',
            child: const Icon(Icons.timer),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
