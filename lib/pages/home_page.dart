import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/random_cards.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RandomCardsWidgetState> _randomCardsKey = GlobalKey<RandomCardsWidgetState>();
  bool _isLoading = false;

  void _handleRefresh() async {
    setState(() => _isLoading = true);
    await _randomCardsKey.currentState?.refreshCards();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CardWatch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SearchBarWidget(),
          const SizedBox(height: 16),
          RandomCardsWidget(key: _randomCardsKey),
          const SizedBox(height: 100), // Spazio per evitare overlap con navbar
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _handleRefresh,
        tooltip: 'Refresh Cards',
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.refresh),
      ),
    );
  }
}
