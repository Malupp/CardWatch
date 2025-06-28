import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/random_cards.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<RandomCardsWidgetState> _randomCardsKey = GlobalKey<RandomCardsWidgetState>();
  bool _isLoading = false;

  void handleRefresh() async {
    setState(() => _isLoading = true);
    await _randomCardsKey.currentState?.refreshCards();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final routeObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<RouteObserver<ModalRoute<void>>>()
        .first;

    return Column(
      children: [
        AppBar(
          title: const Text('CardWatch'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchBarWidget(routeObserver: routeObserver),
              const SizedBox(height: 16),
              RandomCardsWidget(key: _randomCardsKey),
              const SizedBox(height: 100), // Spazio per evitare overlap con navbar
            ],
          ),
        ),
      ],
    );
  }
}
