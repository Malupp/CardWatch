import 'package:flutter/material.dart';
import '../models/card_marketplace.dart';
import '../models/carousel_item.dart';
import '../services/marketplace_service.dart';
import '../widgets/carousel_widget.dart';
import '../widgets/card_detail_dialog.dart';
import '../services/scryfall_api.dart';
import '../services/local_storage.dart';
import 'package:provider/provider.dart';

class ResultsPage extends StatefulWidget {
  final String query;
  const ResultsPage({super.key, required this.query});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = true;
  String? _emptyMessage;
  String? _errorMessage;
  List<CardMarketplace> _allCards = [];
  List<CardMarketplace> _filteredCards = [];
  List<CarouselItem> _allCarouselImages = [];
  int _currentPage = 0;
  final int _cardsPerPage = 10;
  String? _selectedSet;
  String? _selectedCondition;
  String? _selectedLanguage;
  String _foilFilter = 'all';
  double? _maxPrice;

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
    'Poor': 'Poor',
  };

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      List<CardMarketplace> cardsList = [];
      List<CarouselItem> carouselImages = [];

      final blueprintsList = await MarketplaceService.getBlueprintList(
        widget.query,
      );

      for (final blueprint in blueprintsList) {
        List<CardMarketplace> cards = await MarketplaceService.getMarketCard(
          blueprint.id,
        );
        cardsList.addAll(
          cards.map((c) {
            final props = Map<String, dynamic>.from(c.propertiesHash);
            props['name'] = blueprint.name;
            props['blueprintId'] = blueprint.id;
            props['imageUrl'] ??= blueprint.imageUrl;
            props['imageNormalUrl'] ??= blueprint.imageUrl;
            return CardMarketplace(
              user: c.user,
              expansion: c.expansion,
              price: c.price,
              propertiesHash: props,
              quantity: c.quantity,
            );
          }),
        );
      }

      final uniqueConditions = cardsList.map((c) => c.condition).toSet();

      if (mounted) {
        setState(() {
          _conditions.clear();
          for (var condition in uniqueConditions) {
            _conditions[condition] = condition;
          }
        });
      }

      for (final card in cardsList) {
        final alreadyFetched = carouselImages.any(
          (element) => element.description == card.expansion.nameEn,
        );
        if (!alreadyFetched) {
          final image = await ScryfallApi.getCardsImageByExpansionCode(
            widget.query,
            card.expansion.code,
          );
          carouselImages.add(
            CarouselItem(url: image, description: card.expansion.nameEn),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _allCards = cardsList;
        _filteredCards = cardsList;
        _allCarouselImages = carouselImages;
        _emptyMessage = blueprintsList.isEmpty
            ? 'Carta non trovata su CardTrader'
            : 'Nessuna offerta attiva su CardTrader';
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Errore nel caricamento offerte: $e';
      });
    }
  }

  List<String> _uniqueSets() {
    final sets = _allCards
        .map((card) => card.expansion.nameEn)
        .where((set) => set.isNotEmpty)
        .toSet()
        .toList();
    sets.sort();
    return sets;
  }

  List<String> _uniqueLanguages() {
    final languages = _allCards
        .map((card) => card.language)
        .where((language) => language.isNotEmpty && language != 'N/A')
        .toSet()
        .toList();
    languages.sort();
    return languages;
  }

  List<CarouselItem> get _filteredCarouselImages {
    if (_selectedSet == null &&
        _selectedCondition == null &&
        _selectedLanguage == null &&
        _foilFilter == 'all' &&
        _maxPrice == null) {
      return _allCarouselImages;
    }

    // Ottieni i set unici dalle carte filtrate
    final filteredSets = _filteredCards.map((c) => c.expansion.nameEn).toSet();

    // Filtra le immagini del carousel in base ai set delle carte filtrate
    return _allCarouselImages
        .where((item) => filteredSets.contains(item.description))
        .toList();
  }

  void _filterCards() {
    setState(() {
      _filteredCards = _allCards.where((card) {
        bool matchesSet =
            _selectedSet == null || card.expansion.nameEn == _selectedSet;
        bool matchesCondition =
            _selectedCondition == null || card.condition == _selectedCondition;
        bool matchesLanguage =
            _selectedLanguage == null || card.language == _selectedLanguage;
        bool matchesFoil =
            _foilFilter == 'all' ||
            (_foilFilter == 'foil' && card.isFoil) ||
            (_foilFilter == 'nonFoil' && !card.isFoil);
        bool matchesPrice =
            _maxPrice == null ||
            _parsePrice(card.price.formatted) <= _maxPrice!;
        return matchesSet &&
            matchesCondition &&
            matchesLanguage &&
            matchesFoil &&
            matchesPrice;
      }).toList();
      _currentPage = 0;
    });
  }

  List<CardMarketplace> get _currentPageCards {
    final startIndex = _currentPage * _cardsPerPage;
    final endIndex = (startIndex + _cardsPerPage).clamp(
      0,
      _filteredCards.length,
    );
    return _filteredCards.sublist(startIndex, endIndex);
  }

  void _showFilterDialog() {
    var selectedSet = _selectedSet;
    var selectedCondition = _selectedCondition;
    var selectedLanguage = _selectedLanguage;
    var foilFilter = _foilFilter;
    final maxPriceController = TextEditingController(
      text: _maxPrice == null ? '' : _maxPrice!.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtra risultati'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSet,
                  decoration: const InputDecoration(labelText: 'Set'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tutti i set'),
                    ),
                    ..._uniqueSets().map(
                      (set) => DropdownMenuItem(value: set, child: Text(set)),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedSet = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: const InputDecoration(labelText: 'Condizione'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tutte le condizioni'),
                    ),
                    ..._conditions.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedCondition = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: const InputDecoration(labelText: 'Lingua'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tutte le lingue'),
                    ),
                    ..._uniqueLanguages().map(
                      (language) => DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedLanguage = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: foilFilter,
                  decoration: const InputDecoration(labelText: 'Foil'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tutte')),
                    DropdownMenuItem(value: 'foil', child: Text('Solo foil')),
                    DropdownMenuItem(value: 'nonFoil', child: Text('Non foil')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => foilFilter = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prezzo massimo',
                    suffixText: 'EUR',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedSet = null;
                  _selectedCondition = null;
                  _selectedLanguage = null;
                  _foilFilter = 'all';
                  _maxPrice = null;
                });
                _filterCards();
              },
              child: const Text('RESET'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _selectedSet = selectedSet;
                _selectedCondition = selectedCondition;
                _selectedLanguage = selectedLanguage;
                _foilFilter = foilFilter;
                _maxPrice = _parseOptionalPrice(maxPriceController.text);
                _filterCards();
              },
              child: const Text('APPLICA'),
            ),
          ],
        ),
      ),
    ).then((_) => maxPriceController.dispose());
  }

  String? _getImageUrlForCard(CardMarketplace card) {
    final imageNormalUrl = card.propertiesHash['imageNormalUrl']?.toString();
    if (imageNormalUrl != null && imageNormalUrl.isNotEmpty) {
      return imageNormalUrl;
    }

    final imageUrl = card.propertiesHash['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

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
      newProperties['imageNormalUrl'] = imageUrl;
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
  final storage = context.read<LocalStorage>(); // ← context.read per azioni
  final isInCollection = storage.collection.any(
    (c) =>
        c.expansion.nameEn == card.expansion.nameEn &&
        c.user.username == card.user.username,
  );
  if (isInCollection) {
    storage.removeFromCollection(card);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.propertiesHash['name'] ?? card.expansion.nameEn} rimossa dalla collezione')),
    );
  } else {
    storage.addToCollection(_withImageUrl(card));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.propertiesHash['name'] ?? card.expansion.nameEn} aggiunta alla collezione')),
    );
  }
}

  void _toggleWatchlist(CardMarketplace card) {
    final storage = context.read<LocalStorage>(); // ← context.read per azioni
    final isInWatchlist = storage.watchlist.any(
      (c) =>
          c.expansion.nameEn == card.expansion.nameEn &&
          c.user.username == card.user.username,
    );
    if (isInWatchlist) {
      storage.removeFromWatchlist(card);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card.propertiesHash['name'] ?? card.expansion.nameEn} rimossa dalla watchlist',
          ),
        ),
      );
    } else {
      storage.addToWatchlist(_withImageUrl(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card.propertiesHash['name'] ?? card.expansion.nameEn} aggiunta alla watchlist',
          ),
        ),
      );
    }
  }

  String _getConditionLabel(String condition) {
    // Non serve più convertire, usiamo direttamente la condizione
    return condition;
  }

  double _parsePrice(String formatted) {
    return _parseOptionalPrice(formatted) ?? double.infinity;
  }

  double? _parseOptionalPrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned);
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
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
            )
          : _filteredCards.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _emptyMessage ?? 'Nessuna offerta trovata',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                if (_filteredCarouselImages.isNotEmpty) ...[
                  CarouselWidget(items: _filteredCarouselImages),
                  const Divider(),
                ],
                // Controlli di paginazione spostati più in alto
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
                          onPressed:
                              (_currentPage + 1) * _cardsPerPage <
                                  _filteredCards.length
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentPageCards.length,
                    itemBuilder: (context, index) {
                      final card = _currentPageCards[index];
                      final storage = context.read<LocalStorage>();
                      final isInCollection = storage.collection.any(
                        (c) =>
                            c.expansion.nameEn == card.expansion.nameEn &&
                            c.user.username == card.user.username,
                      );
                      final isInWatchlist = storage.watchlist.any(
                        (c) =>
                            c.expansion.nameEn == card.expansion.nameEn &&
                            c.user.username == card.user.username,
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  CardDetailDialog(card: _withImageUrl(card)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                _buildCardImage(card),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.propertiesHash['name'] ??
                                            card.expansion.nameEn,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        card.expansion.nameEn,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        '${card.user.username} - ${_getConditionLabel(card.condition)} - ${card.language}${card.isFoil ? ' - Foil' : ''}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
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
                                  tooltip: isInCollection
                                      ? 'Rimuovi dalla collezione'
                                      : 'Aggiungi alla collezione',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isInWatchlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isInWatchlist ? Colors.red : null,
                                  ),
                                  onPressed: () => _toggleWatchlist(card),
                                  tooltip: isInWatchlist
                                      ? 'Rimuovi dalla watchlist'
                                      : 'Aggiungi alla watchlist',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCardImage(CardMarketplace card) {
    final imageUrl = _getImageUrlForCard(card);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 50,
      height: 75,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 30, color: Colors.grey),
      ),
    );
  }
}
