import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/random_cards.dart';
import '../widgets/refresh_button.dart';
import '../services/notification_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<_RandomCardsWidgetState> _randomCardsKey = GlobalKey();

  void _handleRefresh() async {
    await _randomCardsKey.currentState?.refreshCards();
    setState(() {}); // Forza il rebuild per aggiornare lo stato di isLoading
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _randomCardsKey.currentState?.isLoading ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SearchBarWidget(),
        const SizedBox(height: 16),
        RefreshButton(
          onRefresh: _handleRefresh,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        RandomCardsWidget(key: _randomCardsKey),
        const SizedBox(height: 100), // Spazio per evitare overlap con navbar
      ],
    );
  }
}
