import 'package:flutter/material.dart';

import '../models/card_group.dart';
import '../models/card_marketplace.dart';
import '../services/local_storage.dart';
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
  final List<CardGroup> Function()? groups;
  final void Function(String title)? onAddGroup;
  final void Function(String groupId, String title)? onRenameGroup;
  final void Function(String groupId)? onDeleteGroup;
  final void Function(String groupId, CardMarketplace card)? onAddCardToGroup;
  final void Function(String groupId, CardMarketplace card)?
  onRemoveCardFromGroup;
  final void Function(int index) onNavigate;

  const SavedCardsList({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.drawerIndex,
    required this.cards,
    required this.onRemove,
    this.onSetPriceThreshold,
    this.groups,
    this.onAddGroup,
    this.onRenameGroup,
    this.onDeleteGroup,
    this.onAddCardToGroup,
    this.onRemoveCardFromGroup,
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
  String? _selectedGroupId;
  int _currentPage = 0;
  String? _refreshingCardKey; // Traccia quale carta sta being refreshed

  bool get _groupsEnabled =>
      widget.groups != null &&
      widget.onAddGroup != null &&
      widget.onRenameGroup != null &&
      widget.onDeleteGroup != null &&
      widget.onAddCardToGroup != null &&
      widget.onRemoveCardFromGroup != null;

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
    final selectedGroup = _selectedGroup(_groups);
    final groupKeys = selectedGroup?.cardKeys.toSet();

    return cards.where((card) {
      if (groupKeys != null && !groupKeys.contains(_cardKey(card))) {
        return false;
      }

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

  List<CardGroup> get _groups => widget.groups?.call() ?? const [];

  String _cardKey(CardMarketplace card) =>
      '${card.expansion.nameEn}__${card.user.username}';

  CardGroup? _selectedGroup(List<CardGroup> groups) {
    final groupId = _selectedGroupId;
    if (groupId == null) return null;

    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
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
      _selectedGroupId = null;
      _currentPage = 0;
    });
  }

  Future<String?> _showGroupTitleDialog({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nome gruppo'),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isEmpty) return;
            Navigator.pop(context, trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) return;
              Navigator.pop(context, trimmed);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _createGroup() async {
    final title = await _showGroupTitleDialog(
      title: 'Nuovo gruppo',
      actionLabel: 'CREA',
    );
    if (!mounted || title == null) return;

    widget.onAddGroup?.call(title);
  }

  Future<void> _renameGroup(CardGroup group) async {
    final title = await _showGroupTitleDialog(
      title: 'Rinomina gruppo',
      actionLabel: 'SALVA',
      initialValue: group.title,
    );
    if (!mounted || title == null) return;

    widget.onRenameGroup?.call(group.id, title);
  }

  Future<void> _deleteGroup(CardGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina gruppo'),
        content: Text(
          'Eliminare "${group.title}"? Le carte resteranno salvate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    widget.onDeleteGroup?.call(group.id);
    if (_selectedGroupId == group.id) {
      setState(() => _selectedGroupId = null);
    }
  }

  void _showGroupManager() {
    final groups = _groups;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gruppi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Nuovo gruppo',
                  icon: const Icon(Icons.create_new_folder),
                  onPressed: () {
                    Navigator.pop(context);
                    _createGroup();
                  },
                ),
              ],
            ),
            if (groups.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Nessun gruppo'),
              )
            else
              ...groups.map(
                (group) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(group.title),
                  subtitle: Text('${group.cardKeys.length} carte'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Rinomina',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          _renameGroup(group);
                        },
                      ),
                      IconButton(
                        tooltip: 'Elimina',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteGroup(group);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCardGroups(CardMarketplace card) {
    final groups = _groups;
    final cardKey = _cardKey(card);
    final assignedGroupIds = groups
        .where((group) => group.cardKeys.contains(cardKey))
        .map((group) => group.id)
        .toSet();

    if (groups.isEmpty) {
      _createGroup();
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Gruppi per ${_cardName(card)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...groups.map((group) {
                final assigned = assignedGroupIds.contains(group.id);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(group.title),
                  value: assigned,
                  onChanged: (value) {
                    if (value == true) {
                      assignedGroupIds.add(group.id);
                      widget.onAddCardToGroup?.call(group.id, card);
                    } else {
                      assignedGroupIds.remove(group.id);
                      widget.onRemoveCardFromGroup?.call(group.id, card);
                    }
                    setSheetState(() {});
                  },
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _createGroup();
                },
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Nuovo gruppo'),
              ),
            ],
          ),
        ),
      ),
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore aggiornamento: $e')));
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
          if (_groupsEnabled)
            IconButton(
              icon: const Icon(Icons.folder_copy_outlined),
              tooltip: 'Gestisci gruppi',
              onPressed: _showGroupManager,
            ),
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
                if (_groupsEnabled)
                  _GroupFilterBar(
                    groups: _groups,
                    selectedGroupId: _selectedGroupId,
                    onSelected: (groupId) {
                      setState(() {
                        _selectedGroupId = groupId;
                        _currentPage = 0;
                      });
                    },
                    onCreateGroup: _createGroup,
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
                        final cardKey =
                            '${card.expansion.nameEn}_${card.user.username}';
                        return _SavedCardTile(
                          card: card,
                          imageUrl: _imageUrl(card),
                          title: _cardName(card),
                          priceDelta: _priceDelta(card),
                          isRefreshing: _refreshingCardKey == cardKey,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  CardDetailDialog(card: card),
                            );
                          },
                          onLongPress: _groupsEnabled
                              ? () => _showCardGroups(card)
                              : null,
                          onRemove: () {
                            widget.onRemove(card);
                            setState(() {
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

  _PriceDelta? _priceDelta(CardMarketplace card) {
    final snapshots = LocalStorage().priceSnapshotsFor(card);
    if (snapshots.length < 2) return null;

    final firstPrice = snapshots.first.priceEur;
    final currentPrice = snapshots.last.priceEur;
    if (firstPrice <= 0) return null;

    final delta = currentPrice - firstPrice;
    final deltaPercent = (delta / firstPrice) * 100;
    return _PriceDelta(delta, deltaPercent);
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

class _PriceDelta {
  final double amount;
  final double percent;

  const _PriceDelta(this.amount, this.percent);
}

class _GroupFilterBar extends StatelessWidget {
  final List<CardGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onCreateGroup;

  const _GroupFilterBar({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tutte'),
              selected: selectedGroupId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(group.title),
                selected: selectedGroupId == group.id,
                onSelected: (_) => onSelected(group.id),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('Gruppo'),
              onPressed: onCreateGroup,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final CardMarketplace card;
  final String? imageUrl;
  final String title;
  final _PriceDelta? priceDelta;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onRemove;
  final VoidCallback? onSetPriceThreshold;
  final VoidCallback? onRefreshPrice;
  final bool isRefreshing;

  const _SavedCardTile({
    required this.card,
    required this.imageUrl,
    required this.title,
    required this.priceDelta,
    required this.onTap,
    this.onLongPress,
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
            onLongPress: onLongPress,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (priceDelta != null) ...[
                      _PriceDeltaText(delta: priceDelta!),
                      const SizedBox(height: 4),
                    ],
                    Wrap(
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

class _PriceDeltaText extends StatelessWidget {
  final _PriceDelta delta;

  const _PriceDeltaText({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isDrop = delta.amount <= 0;
    final sign = delta.amount >= 0 ? '+' : '';
    final color = isDrop ? Colors.green : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDrop ? Icons.trending_down : Icons.trending_up,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          'Da aggiunta: $sign${delta.amount.toStringAsFixed(2)} EUR '
          '($sign${delta.percent.toStringAsFixed(1)}%)',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
