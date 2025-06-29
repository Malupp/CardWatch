import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../models/card_marketplace.dart';
import '../widgets/app_drawer.dart';

class WatchlistPage extends StatefulWidget {
  final Function(int) onNavigate;

  const WatchlistPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  @override
  Widget build(BuildContext context) {
    final watchlist = LocalStorage().watchlist;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Watchlist'),
      ),
      drawer: AppDrawer(currentIndex: 2, onSelect: widget.onNavigate),
      body: watchlist.isEmpty
          ? const Center(child: Text('Nessuna carta nella watchlist'))
          : ListView.builder(
              itemCount: watchlist.length,
              itemBuilder: (context, index) {
                final card = watchlist[index];
                return ListTile(
                  leading: (card.propertiesHash['imageUrl'] != null && card.propertiesHash['imageUrl'].toString().isNotEmpty)
                    ? Image.network(
                        card.propertiesHash['imageUrl'],
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 30, color: Colors.grey),
                          ),
                        ),
                      )
                    : null,
                  title: Text(card.propertiesHash['name'] ?? card.expansion.nameEn),
                  subtitle: Text('${card.expansion.nameEn} • ${card.user.username} • ${card.price.formatted}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        LocalStorage().removeFromWatchlist(card);
                      });
                    },
                  ),
                  onTap: () async {
                    String? imageUrl = card.propertiesHash['imageUrl'];
                    if (imageUrl == null || !imageUrl.contains('/normal/')) {
                      try {
                        // Qui puoi usare ScryfallApi.getCardsImageByExpansionCode o una funzione simile
                      } catch (e) {}
                    }
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(card.expansion.nameEn),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.propertiesHash['imageNormalUrl'] != null && card.propertiesHash['imageNormalUrl'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Image.network(
                                  card.propertiesHash['imageNormalUrl'],
                                  height: 250,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Text('Venditore: \t${card.user.username}', style: const TextStyle(fontSize: 16)),
                            Text('Prezzo: \t${card.price.formatted}', style: const TextStyle(fontSize: 16)),
                            Text('Condizione: \t${card.condition}', style: const TextStyle(fontSize: 16)),
                            Text('Foil: \t${card.isFoil ? 'Sì' : 'No'}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text('CHIUDI'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}