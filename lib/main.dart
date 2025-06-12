import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:card_watch/services/notification_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardWatch',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
