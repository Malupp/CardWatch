import 'package:flutter/material.dart';

import '../models/card_marketplace.dart';
import '../services/price_alert_service.dart';
import '../widgets/app_drawer.dart';
import 'card_detail_dialog.dart';

class SavedCardsList extends StatefulWidget {
  final String title;
  final String emptyMessage;
  final int drawerIndex;
  final List<CardMarketplace> Function() cards;
  final void Function(CardMarketplace card) onRemove;
  final void Function(CardMarketplace card, double? thresholdEur)?
  onSetPriceThreshold;
  final void Function(int index) onNavigate;

  const SavedCardsList({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.drawerIndex,
    required this.cards,
    required this.onRemove,
    this.onSetPriceThreshold,
    required this.onNavigate,
  });

  @override
  State<SavedCardsList> createState() => _SavedCardsListState();
}

class _SavedCardsListState extends State<SavedCardsList> {
  static const int _cardsPerPage = 8;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSet;
  String? _selectedCondition;
  String _foilFilter = 'all';
  int _currentPage = 0;
  String? _refreshingCardKey; // Traccia quale carta sta being refreshed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _cardName(CardMarketplace card) {
    final storedName = card.propertiesHash['name']?.toString();
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }
    return card.expansion.nameEn;
  }

  String? _imageUrl(CardMarketplace card) {
    final normal = card.propertiesHash['imageNormalUrl']?.toString();
    if (normal != null && normal.isNotEmpty) return normal;

    final image = card.propertiesHash['imageUrl']?.toString();
    if (image != null && image.isNotEmpty) return image;

    return null;
  }

  List<CardMarketplace> _filteredCards(List<CardMarketplace> cards) {
    final query = _searchQuery.trim().toLowerCase();

    return cards.where((card) {
      final matchesSearch =
          query.isEmpty ||
          _cardName(card).toLowerCase().contains(query) ||
          card.expansion.nameEn.toLowerCase().contains(query);
      final matchesSet =
          _selectedSet == null || card.expansion.nameEn == _selectedSet;
      final matchesCondition =
          _selectedCondition == null || card.condition == _selectedCondition;
      final matchesFoil =
          _foilFilter == 'all' ||
          (_foilFilter == 'foil' && card.isFoil) ||
          (_foilFilter == 'nonFoil' && !card.isFoil);

      return matchesSearch && matchesSet && matchesCondition && matchesFoil;
    }).toList();
  }

  List<String> _uniqueSets(List<CardMarketplace> cards) {
    final sets = cards
        .map((card) => card.expansion.nameEn)
        .where((set) => set.isNotEmpty)
        .toSet()
        .toList();
    sets.sort();
    return sets;
  }

  List<String> _uniqueConditions(List<CardMarketplace> cards) {
    final conditions = cards
        .map((card) => card.condition)
        .where((condition) => condition.isNotEmpty && condition != 'N/A')
        .toSet()
        .toList();
    conditions.sort();
    return conditions;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedSet = null;
      _selectedCondition = null;
      _foilFilter = 'all';
      _currentPage = 0;
    });
  }

  Future<void> _refreshCardPrice(CardMarketplace card) async {
    final cardKey = '${card.expansion.nameEn}_${card.user.username}';
    setState(() => _refreshingCardKey = cardKey);
    try {
      final updated = await PriceAlertService.refreshSingleCardPrice(card);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated != null
                ? 'Prezzo aggiornato: ${updated.price.formatted}'
                : 'Nessun aggiornamento disponibile',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore aggiornamento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _refreshingCardKey = null);
      }
    }
  }

  void _showFilters(List<CardMarketplace> sourceCards) {
    var selectedSet = _selectedSet;
    var selectedCondition = _selectedCondition;
    var foilFilter = _foilFilter;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtra carte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSet,
                  decoration: const InputDecoration(labelText: 'Set'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tutti i set'),
                    ),
                    ..._uniqueSets(sourceCards).map(
                      (set) => DropdownMenuItem<String>(
                        value: set,
                        child: Text(set),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedSet = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: const InputDecoration(labelText: 'Condizione'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tutte le condizioni'),
                    ),
                    ..._uniqueConditions(sourceCards).map(
                      (condition) => DropdownMenuItem<String>(
                        value: condition,
                        child: Text(condition),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedCondition = value);
                  },
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilters();
                },
                child: const Text('RESET'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedSet = selectedSet;
                    _selectedCondition = selectedCondition;
                    _foilFilter = foilFilter;
                    _currentPage = 0;
                  });
                },
                child: const Text('APPLICA'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showThresholdDialog(CardMarketplace card) async {
    final threshold = _priceThresholdEur(card);
    final controller = TextEditingController(
      text: threshold == null ? '' : threshold.toStringAsFixed(2),
    );

    final result = await showDialog<_ThresholdDialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soglia prezzo'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Avvisami sotto',
            suffixText: 'EUR',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, const _ThresholdDialogResult(null));
            },
            child: const Text('RIMUOVI'),
          ),
          TextButton(
            onPressed: () {
              final threshold = _parseOptionalPrice(controller.text);
              if (threshold == null) return;
              Navigator.pop(context, _ThresholdDialogResult(threshold));
            },
            child: const Text('SALVA'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!mounted || result == null) return;

    widget.onSetPriceThreshold?.call(card, result.thresholdEur);

     if (mounted) {
        setState(() {
        widget.onSetPriceThreshold?.call(card, result.thresholdEur);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceCards = widget.cards();
    final filteredCards = _filteredCards(sourceCards);
    final pageCount = filteredCards.isEmpty
        ? 1
        : ((filteredCards.length + _cardsPerPage - 1) ~/ _cardsPerPage);
    final pageIndex = _currentPage >= pageCount ? pageCount - 1 : _currentPage;
    final pageCards = filteredCards
        .skip(pageIndex * _cardsPerPage)
        .take(_cardsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: sourceCards.isEmpty
                ? null
                : () => _showFilters(sourceCards),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: widget.drawerIndex,
        onSelect: widget.onNavigate,
      ),
      body: sourceCards.isEmpty
          ? Center(child: Text(widget.emptyMessage))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cerca tra le carte salvate',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _currentPage = 0;
                                });
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filteredCards.length} di ${sourceCards.length} carte',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                if (filteredCards.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Nessuna carta corrisponde ai filtri'),
                    ),
                  )
                else ...[
                  _PaginationBar(
                    pageIndex: pageIndex,
                    pageCount: pageCount,
                    onPrevious: pageIndex > 0
                        ? () => setState(() => _currentPage = pageIndex - 1)
                        : null,
                    onNext: pageIndex < pageCount - 1
                        ? () => setState(() => _currentPage = pageIndex + 1)
                        : null,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 132),
                      itemCount: pageCards.length,
                      itemBuilder: (context, index) {
                        final card = pageCards[index];
                        final cardKey = '${card.expansion.nameEn}_${card.user.username}';
                        return _SavedCardTile(
                          card: card,
                          imageUrl: _imageUrl(card),
                          title: _cardName(card),
                          isRefreshing: _refreshingCardKey == cardKey,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  CardDetailDialog(card: card),
                            );
                          },
                          onRemove: () {
                            setState(() {
                              widget.onRemove(card);
                              if (pageCards.length == 1 && pageIndex > 0) {
                                _currentPage = pageIndex - 1;
                              }
                            });
                          },
                          onSetPriceThreshold:
                              widget.onSetPriceThreshold == null
                              ? null
                              : () => _showThresholdDialog(card),
                          onRefreshPrice: () => _refreshCardPrice(card),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  double? _parseOptionalPrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned);
  }

  double? _priceThresholdEur(CardMarketplace card) {
    final value = card.propertiesHash['priceThresholdEur'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class _ThresholdDialogResult {
  final double? thresholdEur;

  const _ThresholdDialogResult(this.thresholdEur);
}

class _PaginationBar extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pageIndex,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            'Pagina ${pageIndex + 1} di $pageCount',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final CardMarketplace card;
  final String? imageUrl;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onSetPriceThreshold;
  final VoidCallback? onRefreshPrice;
  final bool isRefreshing;

  const _SavedCardTile({
    required this.card,
    required this.imageUrl,
    required this.title,
    required this.onTap,
    required this.onRemove,
    this.onSetPriceThreshold,
    this.onRefreshPrice,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final threshold = _priceThresholdEur(card);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      width: 56,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                    card.expansion.nameEn,
                    card.user.username,
                    card.condition,
                    if (card.isFoil) 'Foil',
                    card.price.formatted,
                  ]
                  .where((value) => value.isNotEmpty && value != 'N/A')
                  .join(' - '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Rimuovi',
              onPressed: onRemove,
            ),
          ),
          if (onSetPriceThreshold != null || onRefreshPrice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onSetPriceThreshold != null)
                      TextButton.icon(
                        onPressed: onSetPriceThreshold,
                        icon: Icon(
                          threshold == null
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                        ),
                        label: Text(
                          threshold == null
                              ? 'Imposta avviso prezzo'
                              : 'Avvisami sotto ${threshold.toStringAsFixed(2)} EUR',
                        ),
                      ),
                    if (onRefreshPrice != null)
                      TextButton.icon(
                        onPressed: isRefreshing ? null : onRefreshPrice,
                        icon: isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Aggiorna prezzo'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 78,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  double? _priceThresholdEur(CardMarketplace card) {
    final value = card.propertiesHash['priceThresholdEur'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
