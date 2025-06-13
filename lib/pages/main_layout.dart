import 'package:flutter/material.dart';
import '../widgets/bubble_navbar.dart';
import '../widgets/random_cards.dart';
import '../widgets/refresh_button.dart';
import '../widgets/search_bar.dart';
import '../services/notification_services.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(), // senza Scaffold dentro
    CollectionPage(),
    WatchlistPage(),
    DraftPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        title: const Text('CardWatch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: BubbleNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: _currentIndex == 0 ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => NotificationService.showNow(),
            tooltip: 'Open Notifications',
            child: const Icon(Icons.notifications_active),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => NotificationService.showDelayed(),
            tooltip: 'Notifica dopo 30s',
            child: const Icon(Icons.timer),
          ),
        ],
      ) : null,
    );
  }
}

// HomePage SENZA Scaffold (viene gestito dal MainLayout)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RandomCardsWidgetState> _randomCardsKey = GlobalKey<RandomCardsWidgetState>();

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

// Placeholder per le altre pagine
class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Collection',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Le tue carte personali'),
        ],
      ),
    );
  }
}

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Watchlist',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Carte che stai monitorando'),
        ],
      ),
    );
  }
}

class DraftPage extends StatelessWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shuffle, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Draft',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Modalità draft casuale'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profilo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Le tue impostazioni e statistiche'),
        ],
      ),
    );
  }
}