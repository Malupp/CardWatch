import 'package:flutter/material.dart';
import '../models/card_marketplace.dart';
import '../models/carousel_item.dart';
import '../services/marketplace_service.dart';
import '../widgets/carousel_widget.dart';
import '../widgets/custom_card_widget.dart';
import '../services/scryfall_api.dart';
import '../services/local_storage.dart';

class ResultsPage extends StatefulWidget {
  final String query;
  const ResultsPage({super.key, required this.query});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = true;
  List<CardMarketplace> _allCards = [];
  List<CardMarketplace> _filteredCards = [];
  List<CarouselItem> _allCarouselImages = [];
  int _currentPage = 0;
  final int _cardsPerPage = 10;
  String? _selectedSet;
  String? _selectedCondition;

  // Mappa delle condizioni con le loro descrizioni
  final Map<String, String> _conditions = {
    'Near Mint': 'Near Mint',
    'Mint': 'Mint',
    'Excellent': 'Excellent',
    'Good': 'Good',
    'Light Played': 'Light Played',
    'Slightly Played': 'Slightly Played',
    'Moderately Played': 'Moderately Played',
    'Heavily Played': 'Heavily Played',
    'Poor': 'Poor'
  };

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    List<CardMarketplace> cardsList = [];
    List<CarouselItem> carouselImages = [];
    
    final blueprintsList = await MarketplaceService.getBlueprintList(
      widget.query,
    );

    for (final blueprint in blueprintsList) {
      List<CardMarketplace> cards = await MarketplaceService.getMarketCard(
        blueprint.id,
      );
      cardsList.addAll(cards);
    }

    // Debug: stampa tutte le condizioni uniche che arrivano dall'API
    final uniqueConditions = cardsList.map((c) => c.condition).toSet();
    print('Condizioni uniche trovate: $uniqueConditions');

    // Aggiorna la mappa delle condizioni con quelle trovate
    setState(() {
      _conditions.clear();
      for (var condition in uniqueConditions) {
        _conditions[condition] = condition;
      }
    });

    for (final card in cardsList) {
      final alreadyGetted = carouselImages.any(
        (element) => element.description == card.expansion.nameEn
      );
      if (!alreadyGetted) {
        final image = await ScryfallApi.getCardsImageByExpansionCode(
          widget.query,
          card.expansion.code,
        );
        carouselImages.add(
          CarouselItem(url: image, description: card.expansion.nameEn)
        );
      }
    }

    setState(() {
      _loading = false;
      _allCards = cardsList;
      _filteredCards = cardsList;
      _allCarouselImages = carouselImages;
    });
  }

  List<CarouselItem> get _filteredCarouselImages {
    if (_selectedSet == null && _selectedCondition == null) {
      return _allCarouselImages;
    }

    // Ottieni i set unici dalle carte filtrate
    final filteredSets = _filteredCards.map((c) => c.expansion.nameEn).toSet();
    
    // Filtra le immagini del carousel in base ai set delle carte filtrate
    return _allCarouselImages.where((item) => 
      filteredSets.contains(item.description)
    ).toList();
  }

  void _filterCards() {
    setState(() {
      print('Filtraggio in corso...');
      print('Set selezionato: $_selectedSet');
      print('Condizione selezionata: $_selectedCondition');
      
      _filteredCards = _allCards.where((card) {
        bool matchesSet = _selectedSet == null || card.expansion.nameEn == _selectedSet;
        bool matchesCondition = _selectedCondition == null || card.condition == _selectedCondition;
        
        final result = matchesSet && matchesCondition;
        if (_selectedCondition != null) {
          print('Carta: ${card.expansion.nameEn}');
          print('Condizione carta: "${card.condition}"');
          print('Confronto con: "$_selectedCondition"');
          print('Risultato match: $result');
        }
        
        return result;
      }).toList();
      
      print('Carte filtrate: ${_filteredCards.length}');
      _currentPage = 0;
    });
  }

  List<CardMarketplace> get _currentPageCards {
    final startIndex = _currentPage * _cardsPerPage;
    final endIndex = (startIndex + _cardsPerPage).clamp(0, _filteredCards.length);
    return _filteredCards.sublist(startIndex, endIndex);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtra risultati'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSet,
                decoration: const InputDecoration(labelText: 'Set'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tutti i set')),
                  ..._allCards
                      .map((c) => c.expansion.nameEn)
                      .toSet()
                      .map((set) => DropdownMenuItem(value: set, child: Text(set))),
                ],
                onChanged: (value) => setDialogState(() => _selectedSet = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(labelText: 'Condizione'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tutte le condizioni')),
                  ..._conditions.entries.map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  )),
                ],
                onChanged: (value) => setDialogState(() => _selectedCondition = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _selectedSet = null;
                _selectedCondition = null;
                _filterCards();
              },
              child: const Text('RESET'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _filterCards();
              },
              child: const Text('APPLICA'),
            ),
          ],
        ),
      ),
    );
  }

  String? _getImageUrlForCard(CardMarketplace card) {
    // Cerca l'immagine normal dal carousel per il set corrispondente
    final carouselItem = _allCarouselImages.firstWhere(
      (item) => item.description == card.expansion.nameEn,
      orElse: () => CarouselItem(url: '', description: ''),
    );
    return carouselItem.url;
  }

  CardMarketplace _withImageUrl(CardMarketplace card) {
    final imageUrl = _getImageUrlForCard(card);
    final newProperties = Map<String, dynamic>.from(card.propertiesHash);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      newProperties['imageUrl'] = imageUrl;
    }
    return CardMarketplace(
      user: card.user,
      expansion: card.expansion,
      price: card.price,
      propertiesHash: newProperties,
      quantity: card.quantity,
    );
  }

  void _toggleCollection(CardMarketplace card) {
    final isInCollection = LocalStorage().collection.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
    if (isInCollection) {
      LocalStorage().removeFromCollection(card);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.expansion.nameEn} rimossa dalla collezione')),
      );
    } else {
      LocalStorage().addToCollection(_withImageUrl(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.expansion.nameEn} aggiunta alla collezione')),
      );
    }
    setState(() {});
  }

  void _toggleWatchlist(CardMarketplace card) {
    final isInWatchlist = LocalStorage().watchlist.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
    if (isInWatchlist) {
      LocalStorage().removeFromWatchlist(card);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.expansion.nameEn} rimossa dalla watchlist')),
      );
    } else {
      LocalStorage().addToWatchlist(_withImageUrl(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.expansion.nameEn} aggiunta alla watchlist')),
      );
    }
    setState(() {});
  }

  String _getConditionLabel(String condition) {
    // Non serve più convertire, usiamo direttamente la condizione
    return condition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Risultati: ${widget.query}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _filteredCards.isEmpty
          ? const Center(child: Text('Nessuna carta trovata'))
          : Column(
              children: [
                if (_filteredCarouselImages.isNotEmpty) ...[
                  CarouselWidget(items: _filteredCarouselImages),
                  const Divider(),
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentPageCards.length,
                    itemBuilder: (context, index) {
                      final card = _currentPageCards[index];
                      final isInCollection = LocalStorage().collection.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
                      final isInWatchlist = LocalStorage().watchlist.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: InkWell(
                          onTap: () {
                            // TODO: Mostra dettagli carta
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                if (card.propertiesHash['imageUrl'] != null && card.propertiesHash['imageUrl'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.network(
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
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.expansion.nameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${card.user.username} • ${_getConditionLabel(card.condition)}${card.isFoil ? ' • Foil' : ''}',
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  card.price.formatted,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.collections_bookmark_outlined,
                                    color: isInCollection ? Colors.green : null,
                                  ),
                                  onPressed: () => _toggleCollection(card),
                                  tooltip: isInCollection ? 'Rimuovi dalla collezione' : 'Aggiungi alla collezione',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isInWatchlist ? Icons.favorite : Icons.favorite_border,
                                    color: isInWatchlist ? Colors.red : null,
                                  ),
                                  onPressed: () => _toggleWatchlist(card),
                                  tooltip: isInWatchlist ? 'Rimuovi dalla watchlist' : 'Aggiungi alla watchlist',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_filteredCards.length > _cardsPerPage)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        ),
                        Text(
                          'Pagina ${_currentPage + 1} di ${(_filteredCards.length / _cardsPerPage).ceil()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: (_currentPage + 1) * _cardsPerPage < _filteredCards.length
                            ? () => setState(() => _currentPage++)
                            : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
