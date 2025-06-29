import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/unified_card_service.dart';
import 'custom_card_widget.dart';
import '../services/local_storage.dart';
import '../models/card_marketplace.dart';

class RandomCardsWidget extends StatefulWidget {
  const RandomCardsWidget({super.key});

  @override
  State<RandomCardsWidget> createState() => RandomCardsWidgetState();
}

class RandomCardsWidgetState extends State<RandomCardsWidget> 
    with AutomaticKeepAliveClientMixin {
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Mantiene il widget in memoria

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    final cards = await UnifiedCardService.getUnifiedCards(count: 5);
    
    // Controllo se il widget è ancora montato prima di chiamare setState
    if (mounted) {
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    }
  }

  // Metodo pubblico per ricaricare le carte
  Future<void> refreshCards() async {
    await _loadCards();
  }

  // Getter per lo stato di caricamento
  bool get isLoading => _isLoading;

  CardMarketplace _toMarketplace(CardModel card, int blueprintId) {
    return CardMarketplace(
      user: CardUser(username: card.username),
      expansion: CardExpansion(nameEn: card.expansion, code: '', id: blueprintId),
      price: CardPrice(formatted: card.price),
      propertiesHash: {
        'name': card.name,
        'condition': card.condition,
        'foil': card.isFoil,
        'signed': false,
        'language': 'N/A',
        'imageUrl': card.imageUrl,
        'imageNormalUrl': card.imageNormalUrl,
      },
      quantity: card.quantity ?? 1,
    );
  }

  Future<void> _addToCollection(CardModel card) async {
    final blueprints = await MarketplaceService.getBlueprintList(card.name);
    final blueprintId = blueprints.isNotEmpty ? blueprints.first.id : 0;
    LocalStorage().addToCollection(_toMarketplace(card, blueprintId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${card.name} aggiunta alla collezione'),
      ),
    );
  }

  Future<void> _addToWatchlist(CardModel card) async {
    final blueprints = await MarketplaceService.getBlueprintList(card.name);
    final blueprintId = blueprints.isNotEmpty ? blueprints.first.id : 0;
    LocalStorage().addToWatchlist(_toMarketplace(card, blueprintId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${card.name} aggiunta alla watchlist'),
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup quando il widget viene distrutto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Richiesto per AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento carte...'),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(card.name),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.imageNormalUrl != null && card.imageNormalUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Image.network(
                                  card.imageNormalUrl!,
                                  height: 250,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    card.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              // Tutte le info come CustomCardWidget
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (card.artist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'by ${card.artist}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    _buildDetailRow('Set', card.expansion),
                    if (card.price.contains('(Foil:'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Prezzo Normale',
                            card.price.split('(Foil:')[0].trim(),
                            valueStyle: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          _buildDetailRow(
                            'Prezzo Foil',
                            card.price.split('(Foil:')[1].replaceAll(')', '').trim(),
                            valueStyle: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    else if (card.price.contains('(Foil)'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Prezzo',
                            card.price.replaceAll(' (Foil)', ''),
                            valueStyle: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          _buildDetailRow(
                            'Tipo',
                            'Foil',
                            valueStyle: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    else
                      _buildDetailRow(
                        'Prezzo',
                        card.price,
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (card.condition != 'N/A')
                      _buildDetailRow('Condizione', card.condition),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildDetailChip('Foil', card.isFoil ? 'Sì' : 'No'),
                        if (card.graded) _buildDetailChip('Graded', 'Sì'),
                        if (card.quantity != null)
                          _buildDetailChip('Disponibili', '${card.quantity}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (card.username != 'N/A')
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Venduto da ${card.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  Builder(
                    builder: (context) {
                      final isInCollection = LocalStorage().collection.any((c) => c.expansion.nameEn == card.expansion && c.user.username == card.username);
                      final isInWatchlist = LocalStorage().watchlist.any((c) => c.expansion.nameEn == card.expansion && c.user.username == card.username);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: Icon(
                              Icons.collections_bookmark,
                              color: isInCollection ? Colors.green : null,
                            ),
                            label: const Text('Collezione'),
                            onPressed: () => _addToCollection(card),
                          ),
                          TextButton.icon(
                            icon: Icon(
                              isInWatchlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWatchlist ? Colors.red : null,
                            ),
                            label: const Text('Watchlist'),
                            onPressed: () => _addToWatchlist(card),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helpers per dettagli (copiati da CustomCardWidget)
  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: Colors.grey[100],
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
