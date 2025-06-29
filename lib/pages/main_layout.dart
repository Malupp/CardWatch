import 'package:flutter/material.dart';
import '../widgets/bubble_navbar.dart';
import 'home_page.dart';
import 'collection_page.dart';
import 'watchlist_page.dart';
import 'draft_page.dart';
import 'profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  late final List<Widget> _pages;

  void _onPageSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homePageKey),
      CollectionPage(onNavigate: (index) => setState(() => _currentIndex = index)),
      WatchlistPage(onNavigate: (index) => setState(() => _currentIndex = index)),
      DraftPage(onNavigate: (index) => setState(() => _currentIndex = index)),
      ProfilePage(onNavigate: (index) => setState(() => _currentIndex = index)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: _pages[_currentIndex],
          ),
          if (_currentIndex == 0)
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: BubbleNavbar(
                currentIndex: _currentIndex,
                onTap: _onPageSelected,
              ),
            ),
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 100,
              child: FloatingActionButton(
                onPressed: () {
                  _homePageKey.currentState?.handleRefresh();
                },
                tooltip: 'Refresh Cards',
                child: const Icon(Icons.refresh),
              ),
            ),
        ],
      ),
    );
  }
}

