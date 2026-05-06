import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../models/card_marketplace.dart';
import '../widgets/app_drawer.dart';

class CollectionPage extends StatefulWidget {
  final Function(int) onNavigate;

  const CollectionPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  String? _getImageUrl(CardMarketplace card) {
    final imageNormalUrl = card.propertiesHash['imageNormalUrl']?.toString();
    if (imageNormalUrl != null && imageNormalUrl.isNotEmpty) {
      return imageNormalUrl;
    }

    final imageUrl = card.propertiesHash['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final collection = LocalStorage().collection;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('La Tua Collezione'),
      ),
      drawer: AppDrawer(currentIndex: 1, onSelect: widget.onNavigate),
      body: collection.isEmpty
          ? const Center(child: Text('Nessuna carta nella collezione'))
          : ListView.builder(
              itemCount: collection.length,
              itemBuilder: (context, index) {
                final card = collection[index];
                final imageUrl = _getImageUrl(card);
                return ListTile(
                  leading: imageUrl != null
                    ? Image.network(
                        imageUrl,
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
                        LocalStorage().removeFromCollection(card);
                      });
                    },
                  ),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(card.expansion.nameEn),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Image.network(
                                  imageUrl,
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
