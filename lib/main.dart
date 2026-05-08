import 'package:flutter/material.dart';
import 'pages/main_layout.dart';
import 'package:card_watch/services/notification_services.dart';
import 'package:card_watch/services/price_alert_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';
import 'services/local_storage.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == PriceAlertService.backgroundTaskName) {
      await PriceAlertService.checkForLowerPrices();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startBackgroundServices();
  });
}

Future<void> _startBackgroundServices() async {
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await PriceAlertService.scheduleBackgroundChecks();
  } catch (e) {
    debugPrint('Workmanager non inizializzato: $e');
  }

  final autoCheckEnabled = await PriceAlertService.getAutoCheckEnabled();
  if (!autoCheckEnabled) return;

  try {
    await PriceAlertService.checkForLowerPrices();
  } catch (e) {
    debugPrint('Controllo prezzi iniziale non riuscito: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final RouteObserver<ModalRoute<void>> routeObserver =
        RouteObserver<ModalRoute<void>>();

    return ChangeNotifierProvider<LocalStorage>( // ← aggiunto
      create: (_) => LocalStorage(),
      child: MaterialApp(
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
      ),
    );
  }
}