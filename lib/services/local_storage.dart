import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_marketplace.dart';
import '../models/card_group.dart';
import '../models/price_snapshot.dart';
import 'scryfall_api.dart';

class LocalStorage extends ChangeNotifier {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal() {
    _loadData();
  }

  final List<CardMarketplace> _collection = [];
  final List<CardMarketplace> _watchlist = [];
  final List<CardGroup> _collectionGroups = [];
  final List<CardGroup> _watchlistGroups = [];
  final Map<String, List<PriceSnapshot>> _priceSnapshots = {};

  List<CardMarketplace> get collection => List.unmodifiable(_collection);
  List<CardMarketplace> get watchlist => List.unmodifiable(_watchlist);
  List<CardGroup> get collectionGroups => List.unmodifiable(_collectionGroups);
  List<CardGroup> get watchlistGroups => List.unmodifiable(_watchlistGroups);
  List<PriceSnapshot> priceSnapshotsFor(CardMarketplace card) =>
      List.unmodifiable(_priceSnapshots[_cardKey(card)] ?? const []);

  // ---------------------------------------------------------------------------
  // Load / Save
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionJson = prefs.getStringList('collection') ?? [];
    final watchlistJson = prefs.getStringList('watchlist') ?? [];
    final collectionGroupsJson = prefs.getStringList('collection_groups') ?? [];
    final watchlistGroupsJson = prefs.getStringList('watchlist_groups') ?? [];
    final priceSnapshotsJson = prefs.getString('price_snapshots');

    _collection.clear();
    _collection.addAll(
      collectionJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))),
    );

    _watchlist.clear();
    _watchlist.addAll(
      watchlistJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))),
    );

    _collectionGroups.clear();
    _collectionGroups.addAll(
      collectionGroupsJson.map((e) => CardGroup.fromJson(jsonDecode(e))),
    );

    _watchlistGroups.clear();
    _watchlistGroups.addAll(
      watchlistGroupsJson.map((e) => CardGroup.fromJson(jsonDecode(e))),
    );

    _priceSnapshots.clear();
    if (priceSnapshotsJson != null && priceSnapshotsJson.isNotEmpty) {
      final decoded = jsonDecode(priceSnapshotsJson);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value is List) {
            _priceSnapshots[key.toString()] = value.whereType<Map>().map((
              item,
            ) {
              return PriceSnapshot.fromJson(Map<String, dynamic>.from(item));
            }).toList();
          }
        });
      }
    }

    notifyListeners();
  }

  Future<void> _saveCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'collection',
      _collection.map((c) => jsonEncode(_toJson(c))).toList(),
    );
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'watchlist',
      _watchlist.map((c) => jsonEncode(_toJson(c))).toList(),
    );
  }

  Future<void> _saveCollectionGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'collection_groups',
      _collectionGroups.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }

  Future<void> _saveWatchlistGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'watchlist_groups',
      _watchlistGroups.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }

  Future<void> _savePriceSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _priceSnapshots.map(
      (key, snapshots) => MapEntry(
        key,
        snapshots.map((snapshot) => snapshot.toJson()).toList(),
      ),
    );
    await prefs.setString('price_snapshots', jsonEncode(encoded));
  }

  Map<String, dynamic> _toJson(CardMarketplace card) {
    return {
      'user': {'username': card.user.username},
      'expansion': {
        'name_en': card.expansion.nameEn,
        'code': card.expansion.code,
        'id': card.expansion.id,
      },
      'price': {'formatted': card.price.formatted},
      'properties_hash': card.propertiesHash,
      'quantity': card.quantity,
    };
  }

  // ---------------------------------------------------------------------------
  // Collection
  // ---------------------------------------------------------------------------

  void addToCollection(CardMarketplace card) {
    if (_collection.any((c) => _sameCard(c, card))) return;
    _collection.add(card);
    _recordPriceSnapshot(card);
    _saveCollection();
    notifyListeners();
    _enrichStoredCardWithScryfall(card, isWatchlist: false);
  }

  void removeFromCollection(CardMarketplace card) {
    _collection.removeWhere((c) => _sameCard(c, card));
    _saveCollection();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Watchlist
  // ---------------------------------------------------------------------------

  void addToWatchlist(CardMarketplace card) {
    if (_watchlist.any((c) => _sameCard(c, card))) return;
    _watchlist.add(card);
    _recordPriceSnapshot(card);
    _saveWatchlist();
    notifyListeners();
    _enrichStoredCardWithScryfall(card, isWatchlist: true);
  }

  void removeFromWatchlist(CardMarketplace card) {
    _watchlist.removeWhere((c) => _sameCard(c, card));
    _saveWatchlist();
    notifyListeners();
  }

  void setWatchlistPriceThreshold(CardMarketplace card, double? thresholdEur) {
    final index = _watchlist.indexWhere((c) => _sameCard(c, card));
    if (index == -1) return;

    final properties = Map<String, dynamic>.from(
      _watchlist[index].propertiesHash,
    );

    if (thresholdEur == null) {
      properties.remove('priceThresholdEur');
    } else {
      properties['priceThresholdEur'] = thresholdEur;
    }

    _watchlist[index] = _watchlist[index].copyWith(propertiesHash: properties);
    _saveWatchlist();
    notifyListeners();
  }

  void updateCardPrice(CardMarketplace oldCard, CardMarketplace newCard) {
    final oldCardKey = _cardKey(oldCard);

    // Update collection
    final collectionIndex = _collection.indexWhere(
      (c) => _sameCard(c, oldCard),
    );
    if (collectionIndex != -1) {
      final current = _collection[collectionIndex];
      _collection[collectionIndex] = current.copyWith(
        price: newCard.price,
        quantity: newCard.quantity,
        propertiesHash: {...current.propertiesHash, ...newCard.propertiesHash},
      );
      _saveCollection();
      _recordPriceSnapshotForKey(oldCardKey, newCard.price.formatted);
    }

    // Update watchlist
    final watchlistIndex = _watchlist.indexWhere((c) => _sameCard(c, oldCard));
    if (watchlistIndex != -1) {
      final current = _watchlist[watchlistIndex];
      final properties = Map<String, dynamic>.from(current.propertiesHash);
      _watchlist[watchlistIndex] = current.copyWith(
        price: newCard.price,
        quantity: newCard.quantity,
        propertiesHash: properties,
      );
      _saveWatchlist();
      _recordPriceSnapshotForKey(oldCardKey, newCard.price.formatted);
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Groups - Collection
  // ---------------------------------------------------------------------------

  void addCollectionGroup(String title) {
    final group = CardGroup(title: title, cardKeys: []);
    _collectionGroups.add(group);
    _saveCollectionGroups();
    notifyListeners();
  }

  void renameCollectionGroup(String groupId, String newTitle) {
    final index = _collectionGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    _collectionGroups[index] = _collectionGroups[index].copyWith(
      title: newTitle,
    );
    _saveCollectionGroups();
    notifyListeners();
  }

  void deleteCollectionGroup(String groupId) {
    _collectionGroups.removeWhere((g) => g.id == groupId);
    _saveCollectionGroups();
    notifyListeners();
  }

  void addCardToCollectionGroup(String groupId, CardMarketplace card) {
    final index = _collectionGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final cardKey = _cardKey(card);
    if (!_collectionGroups[index].cardKeys.contains(cardKey)) {
      _collectionGroups[index] = _collectionGroups[index].copyWith(
        cardKeys: [..._collectionGroups[index].cardKeys, cardKey],
      );
      _saveCollectionGroups();
      notifyListeners();
    }
  }

  void removeCardFromCollectionGroup(String groupId, CardMarketplace card) {
    final index = _collectionGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final cardKey = _cardKey(card);
    final updatedKeys = _collectionGroups[index].cardKeys
        .where((k) => k != cardKey)
        .toList();
    _collectionGroups[index] = _collectionGroups[index].copyWith(
      cardKeys: updatedKeys,
    );
    _saveCollectionGroups();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Groups - Watchlist
  // ---------------------------------------------------------------------------

  void addWatchlistGroup(String title) {
    final group = CardGroup(title: title, cardKeys: []);
    _watchlistGroups.add(group);
    _saveWatchlistGroups();
    notifyListeners();
  }

  void renameWatchlistGroup(String groupId, String newTitle) {
    final index = _watchlistGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    _watchlistGroups[index] = _watchlistGroups[index].copyWith(title: newTitle);
    _saveWatchlistGroups();
    notifyListeners();
  }

  void deleteWatchlistGroup(String groupId) {
    _watchlistGroups.removeWhere((g) => g.id == groupId);
    _saveWatchlistGroups();
    notifyListeners();
  }

  void addCardToWatchlistGroup(String groupId, CardMarketplace card) {
    final index = _watchlistGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final cardKey = _cardKey(card);
    if (!_watchlistGroups[index].cardKeys.contains(cardKey)) {
      _watchlistGroups[index] = _watchlistGroups[index].copyWith(
        cardKeys: [..._watchlistGroups[index].cardKeys, cardKey],
      );
      _saveWatchlistGroups();
      notifyListeners();
    }
  }

  void removeCardFromWatchlistGroup(String groupId, CardMarketplace card) {
    final index = _watchlistGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final cardKey = _cardKey(card);
    final updatedKeys = _watchlistGroups[index].cardKeys
        .where((k) => k != cardKey)
        .toList();
    _watchlistGroups[index] = _watchlistGroups[index].copyWith(
      cardKeys: updatedKeys,
    );
    _saveWatchlistGroups();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _cardKey(CardMarketplace card) =>
      '${card.expansion.nameEn}__${card.user.username}';

  bool _sameCard(CardMarketplace a, CardMarketplace b) =>
      a.expansion.nameEn == b.expansion.nameEn &&
      a.user.username == b.user.username;

  void recordPriceSnapshot(CardMarketplace card) {
    _recordPriceSnapshot(card);
    notifyListeners();
  }

  void _recordPriceSnapshot(CardMarketplace card) {
    _recordPriceSnapshotForKey(_cardKey(card), card.price.formatted);
  }

  void _recordPriceSnapshotForKey(String cardKey, String formattedPrice) {
    final price = _parsePrice(formattedPrice);
    if (price == null) return;

    final now = DateTime.now();
    final snapshots = _priceSnapshots.putIfAbsent(cardKey, () => []);
    final snapshot = PriceSnapshot(date: now, priceEur: price);

    if (snapshots.isNotEmpty && _sameDay(snapshots.last.date, now)) {
      snapshots[snapshots.length - 1] = snapshot;
    } else {
      snapshots.add(snapshot);
    }

    _savePriceSnapshots();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double? _parsePrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned);
  }

  bool _hasScryfallMetadata(CardMarketplace card) {
    final properties = card.propertiesHash;
    return properties.containsKey('colors') &&
        properties.containsKey('rarity') &&
        properties.containsKey('cmc') &&
        properties.containsKey('type_line');
  }

  String _cardName(CardMarketplace card) {
    final storedName = card.propertiesHash['name']?.toString();
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName.trim();
    }
    return card.expansion.nameEn.trim();
  }

  Future<void> _enrichStoredCardWithScryfall(
    CardMarketplace card, {
    required bool isWatchlist,
  }) async {
    if (_hasScryfallMetadata(card)) return;

    try {
      final details = await ScryfallApi.fetchCardDetails(
        _cardName(card),
        setCode: card.expansion.code,
      );
      if (details == null) return;

      final cards = isWatchlist ? _watchlist : _collection;
      final index = cards.indexWhere((candidate) => _sameCard(candidate, card));
      if (index == -1) return;

      final current = cards[index];
      if (_hasScryfallMetadata(current)) return;

      final properties = Map<String, dynamic>.from(current.propertiesHash);
      properties['scryfallName'] = details.name;
      properties['scryfallSetName'] = details.setName;
      properties['scryfallSetCode'] = details.setCode;
      properties['colors'] = details.colors;
      properties['rarity'] = details.rarity;
      properties['cmc'] = details.manaValue;
      properties['type_line'] = details.typeLine;
      properties['oracle_text'] = details.oracleText;
      properties['legalities'] = details.legalities;
      properties['scryfallPrices'] = details.prices;
      if (details.imageUrl.isNotEmpty) {
        properties['imageNormalUrl'] ??= details.imageUrl;
        properties['imageUrl'] ??= details.imageUrl;
      }

      cards[index] = current.copyWith(propertiesHash: properties);
      if (isWatchlist) {
        await _saveWatchlist();
      } else {
        await _saveCollection();
      }
      notifyListeners();
    } catch (_) {
      // Scryfall metadata improves filtering/details, but saving the card must
      // keep working even when enrichment fails.
    }
  }
}
