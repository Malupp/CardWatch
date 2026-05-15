import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_storage.dart';
import '../widgets/saved_cards_list.dart';

class WatchlistPage extends StatelessWidget {
  final Function(int) onNavigate;
  const WatchlistPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final storage = context
        .watch<LocalStorage>(); // ← si ricostruisce automaticamente

    return SavedCardsList(
      title: 'Watchlist',
      emptyMessage: 'Nessuna carta nella watchlist',
      drawerIndex: 2,
      cards: () => storage.watchlist,
      onRemove: storage.removeFromWatchlist,
      onSetPriceThreshold: storage.setWatchlistPriceThreshold,
      groups: () => storage.watchlistGroups,
      onAddGroup: storage.addWatchlistGroup,
      onRenameGroup: storage.renameWatchlistGroup,
      onDeleteGroup: storage.deleteWatchlistGroup,
      onAddCardToGroup: storage.addCardToWatchlistGroup,
      onRemoveCardFromGroup: storage.removeCardFromWatchlistGroup,
      onNavigate: onNavigate,
    );
  }
}
