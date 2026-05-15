import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';
import '../models/scryfall_set.dart';
import '../models/card_model.dart';
import 'results_page.dart';
import '../widgets/app_drawer.dart';

class DraftPage extends StatefulWidget {
  final Function(int) onNavigate;

  const DraftPage({super.key, required this.onNavigate});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const Map<String, String> _colorLabels = {
    'W': 'Bianco',
    'U': 'Blu',
    'B': 'Nero',
    'R': 'Rosso',
    'G': 'Verde',
    'C': 'Incolore',
  };
  static const List<String> _rarityFilters = [
    'common',
    'uncommon',
    'rare',
    'mythic',
  ];
  static const List<String> _typeFilters = [
    'Creature',
    'Instant',
    'Sorcery',
    'Artifact',
    'Enchantment',
    'Planeswalker',
    'Land',
    'Battle',
  ];

  List<ScryfallSet> _sets = [];
  ScryfallSet? _selectedSet;
  bool _loadingSets = true;
  bool _loadingCards = false;
  List<CardModel> _cards = [];
  List<CardModel> _filteredCards = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedColors = <String>{};
  String? _selectedRarity;
  String? _selectedType;
  double _maxManaValue = 16;
  RangeValues _manaValueRange = const RangeValues(0, 16);

  int _currentPage = 0;
  final int _cardsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    final sets = await ScryfallApi.fetchSets();
    if (!mounted) return;
    setState(() {
      _sets = sets;
      _loadingSets = false;
    });
  }

  Future<void> _loadCardsForSet(String code) async {
    setState(() {
      _loadingCards = true;
      _cards = [];
    });
    final cards = await ScryfallApi.fetchCardsBySet(code);
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _maxManaValue = _resolveMaxManaValue(cards);
      _manaValueRange = RangeValues(0, _maxManaValue);
      _applyFilters();
      _loadingCards = false;
    });
  }

  void _filterCards(String query) {
    setState(_applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final manaFilterActive =
        _manaValueRange.start > 0 || _manaValueRange.end < _maxManaValue;

    _filteredCards = _cards.where((card) {
      if (query.isNotEmpty && !card.name.toLowerCase().contains(query)) {
        return false;
      }

      if (_selectedColors.isNotEmpty && !_matchesColorFilter(card)) {
        return false;
      }

      if (_selectedRarity != null && card.rarity != _selectedRarity) {
        return false;
      }

      if (manaFilterActive) {
        final manaValue = card.manaValue;
        if (manaValue == null ||
            manaValue < _manaValueRange.start ||
            manaValue > _manaValueRange.end) {
          return false;
        }
      }

      if (_selectedType != null) {
        final typeLine = card.typeLine?.toLowerCase() ?? '';
        if (!typeLine.contains(_selectedType!.toLowerCase())) return false;
      }

      return true;
    }).toList();
    _currentPage = 0;
  }

  bool _matchesColorFilter(CardModel card) {
    final cardColors = card.colors.toSet();
    final requiresColorless = _selectedColors.contains('C');
    final selectedColored = _selectedColors
        .where((color) => color != 'C')
        .toList();

    if (requiresColorless && cardColors.isNotEmpty) return false;
    return selectedColored.every(cardColors.contains);
  }

  double _resolveMaxManaValue(List<CardModel> cards) {
    var maxValue = 7.0;
    for (final card in cards) {
      final manaValue = card.manaValue;
      if (manaValue != null && manaValue > maxValue) {
        maxValue = manaValue;
      }
    }
    return maxValue.ceilToDouble().clamp(1, 16).toDouble();
  }

  void _clearFilters() {
    setState(() {
      _selectedColors.clear();
      _selectedRarity = null;
      _selectedType = null;
      _manaValueRange = RangeValues(0, _maxManaValue);
      _applyFilters();
    });
  }

  List<CardModel> get _currentPageCards {
    final startIndex = _currentPage * _cardsPerPage;
    final endIndex = (startIndex + _cardsPerPage).clamp(
      0,
      _filteredCards.length,
    );
    return _filteredCards.sublist(startIndex, endIndex);
  }

  void _showCardDetails(CardModel card) {
    final imageUrl =
        (card.imageNormalUrl != null && card.imageNormalUrl!.isNotEmpty)
        ? card.imageNormalUrl!
        : card.imageUrl;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 96,
                          height: 134,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(width: 96, height: 134),
                        ),
                      )
                    else
                      _buildImagePlaceholder(width: 96, height: 134),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(card.expansion),
                          if (card.typeLine != null &&
                              card.typeLine!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(card.typeLine!),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            card.price,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (card.oracleText != null && card.oracleText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(card.oracleText!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResultsPage(query: card.name),
                            ),
                          );
                        },
                        icon: const Icon(Icons.storefront),
                        label: const Text('Cerca offerte'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Modalità Draft'),
      ),
      drawer: AppDrawer(currentIndex: 3, onSelect: widget.onNavigate),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _loadingSets
                ? const CircularProgressIndicator()
                : Autocomplete<ScryfallSet>(
                    initialValue: _selectedSet != null
                        ? TextEditingValue(text: _selectedSet!.name)
                        : const TextEditingValue(),
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.isEmpty) {
                        return const Iterable<ScryfallSet>.empty();
                      }
                      return _sets.where(
                        (s) => s.name.toLowerCase().contains(
                          value.text.toLowerCase(),
                        ),
                      );
                    },
                    displayStringForOption: (s) => s.name,
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Cerca espansione',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          );
                        },
                    onSelected: (s) {
                      setState(() => _selectedSet = s);
                      _loadCardsForSet(s.code);
                    },
                  ),
            const SizedBox(height: 16),
            if (_selectedSet != null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cerca carta',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: _filterCards,
              ),
              const SizedBox(height: 12),
              _buildFilterPanel(context),
              const SizedBox(height: 16),
            ],
            _loadingCards
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: Column(
                      children: [
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
                                  "Pagina ${_currentPage + 1} di ${(_filteredCards.length / _cardsPerPage).ceil()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          child: _filteredCards.isEmpty && _cards.isNotEmpty
                              ? const Center(
                                  child: Text(
                                    'Nessuna carta con questi filtri',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _currentPageCards.length,
                                  itemBuilder: (context, index) {
                                    final card = _currentPageCards[index];
                                    return ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                      leading: _buildCardImage(card),
                                      title: Text(
                                        card.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        _draftCardSubtitle(card),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _showCardDetails(card),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    final activeFilters = _activeFilterCount;
    final manaMax = _maxManaValue;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: activeFilters > 0,
        leading: const Icon(Icons.filter_alt),
        title: Text(activeFilters == 0 ? 'Filtri' : 'Filtri ($activeFilters)'),
        subtitle: Text('${_filteredCards.length} di ${_cards.length} carte'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _colorLabels.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value),
                  selected: _selectedColors.contains(entry.key),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedColors.add(entry.key)
                          : _selectedColors.remove(entry.key);
                      _applyFilters();
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedRarity,
            decoration: const InputDecoration(
              labelText: 'Rarità',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tutte'),
              ),
              ..._rarityFilters.map(
                (rarity) => DropdownMenuItem<String?>(
                  value: rarity,
                  child: Text(_formatRarity(rarity)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRarity = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipo carta',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tutti'),
              ),
              ..._typeFilters.map(
                (type) =>
                    DropdownMenuItem<String?>(value: type, child: Text(type)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.speed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mana value ${_formatManaValue(_manaValueRange.start)}-${_formatManaValue(_manaValueRange.end)}',
              ),
            ],
          ),
          RangeSlider(
            values: _manaValueRange,
            min: 0,
            max: manaMax,
            divisions: manaMax.round(),
            labels: RangeLabels(
              _formatManaValue(_manaValueRange.start),
              _formatManaValue(_manaValueRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _manaValueRange = RangeValues(
                  values.start.roundToDouble(),
                  values.end.roundToDouble(),
                );
                _applyFilters();
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: activeFilters == 0 ? null : _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedColors.isNotEmpty) count++;
    if (_selectedRarity != null) count++;
    if (_selectedType != null) count++;
    if (_manaValueRange.start > 0 || _manaValueRange.end < _maxManaValue) {
      count++;
    }
    return count;
  }

  String _draftCardSubtitle(CardModel card) {
    final parts = <String>[
      if (card.typeLine != null && card.typeLine!.isNotEmpty) card.typeLine!,
      if (card.rarity != null && card.rarity!.isNotEmpty)
        _formatRarity(card.rarity!),
      if (card.manaValue != null) 'MV ${_formatManaValue(card.manaValue!)}',
    ];
    return parts.join(' - ');
  }

  static String _formatRarity(String rarity) {
    if (rarity.isEmpty) return rarity;
    return rarity[0].toUpperCase() + rarity.substring(1);
  }

  static String _formatManaValue(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  Widget _buildCardImage(CardModel card) {
    // Prova prima l'immagine principale
    if (card.imageUrl.isNotEmpty) {
      return Image.network(
        card.imageUrl,
        width: 36,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 36,
            height: 54,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    // Se non c'è immagine principale, prova l'immagine normale
    if (card.imageNormalUrl != null && card.imageNormalUrl!.isNotEmpty) {
      return Image.network(
        card.imageNormalUrl!,
        width: 36,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 36,
            height: 54,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    // Se non ci sono immagini, mostra placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder({double width = 36, double height = 54}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 20,
        color: Colors.grey,
      ),
    );
  }
}
