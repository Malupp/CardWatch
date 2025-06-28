import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'pages/main_layout.dart';
import 'package:card_watch/services/notification_services.dart';
import 'package:card_watch/services/price_alert_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

const String priceAlertTask = 'price_alert_task';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == priceAlertTask) {
      await PriceAlertService.checkForLowerPrices();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  await PriceAlertService.checkForLowerPrices();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  await Workmanager().registerPeriodicTask(
    '1',
    priceAlertTask,
    frequency: const Duration(minutes: 30),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
    
    return MaterialApp(
      title: 'CardWatch',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainLayout(),
    );
  }
}
