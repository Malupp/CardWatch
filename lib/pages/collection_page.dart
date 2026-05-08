import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_storage.dart';
import '../widgets/saved_cards_list.dart';

class CollectionPage extends StatelessWidget {
  final Function(int) onNavigate;
  const CollectionPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorage>();

    return SavedCardsList(
      title: 'La Tua Collezione',
      emptyMessage: 'Nessuna carta nella collezione',
      drawerIndex: 1,
      cards: () => storage.collection,
      onRemove: storage.removeFromCollection,
      onNavigate: onNavigate,
    );
  }
}