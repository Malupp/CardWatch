import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

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

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        setState(() => _isLoading = true);
        final results = await _fetchSuggestions(value);
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    final url = Uri.parse('https://api.scryfall.com/cards/autocomplete?q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      final List<dynamic> data = jsonBody['data'];
      return data.cast<String>();
    } else {
      throw Exception('Errore nella richiesta');
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() => _suggestions = []);
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
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.pink),
                      onPressed: () {
                        // Azione per il cuore (puoi aggiungere la tua logica qui)
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onTextChanged,
                        decoration: const InputDecoration(
                          labelText: 'Cerca...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlaceholderPage(selected: _controller.text),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(),
                  ),
                if (_suggestions.isNotEmpty)
                  ..._suggestions.map(
                    (s) => ListTile(
                      title: Text(s),
                      onTap: () => _selectSuggestion(s),
                    ),
                  ),
              ],
            ),
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
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String selected;
  const PlaceholderPage({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Pagina')),
      body: Center(
        child: Text('Hai selezionato: $selected'),
      ),
    );
  }
}
