import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import '../widgets/saved_cards_list.dart';

class WatchlistPage extends StatelessWidget {
  final Function(int) onNavigate;

  const WatchlistPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SavedCardsList(
      title: 'Watchlist',
      emptyMessage: 'Nessuna carta nella watchlist',
      drawerIndex: 2,
      cards: () => LocalStorage().watchlist,
      onRemove: LocalStorage().removeFromWatchlist,
      onNavigate: onNavigate,
    );
  }
}
