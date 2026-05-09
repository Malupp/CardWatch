import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_marketplace.dart';
import '../models/card_group.dart';

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

  List<CardMarketplace> get collection => List.unmodifiable(_collection);
  List<CardMarketplace> get watchlist => List.unmodifiable(_watchlist);
  List<CardGroup> get collectionGroups =>
      List.unmodifiable(_collectionGroups);
  List<CardGroup> get watchlistGroups => List.unmodifiable(_watchlistGroups);

  // ---------------------------------------------------------------------------
  // Load / Save
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionJson = prefs.getStringList('collection') ?? [];
    final watchlistJson = prefs.getStringList('watchlist') ?? [];
    final collectionGroupsJson = prefs.getStringList('collection_groups') ?? [];
    final watchlistGroupsJson = prefs.getStringList('watchlist_groups') ?? [];

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
      collectionGroupsJson
          .map((e) => CardGroup.fromJson(jsonDecode(e))),
    );

    _watchlistGroups.clear();
    _watchlistGroups.addAll(
      watchlistGroupsJson.map((e) => CardGroup.fromJson(jsonDecode(e))),
    );

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
    _saveCollection();
    notifyListeners();
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
    _saveWatchlist();
    notifyListeners();
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
    // Update collection
    final collectionIndex = _collection.indexWhere((c) => _sameCard(c, oldCard));
    if (collectionIndex != -1) {
      _collection[collectionIndex] = newCard.copyWith(
        propertiesHash: {
          ..._collection[collectionIndex].propertiesHash,
          ...newCard.propertiesHash,
        },
      );
      _saveCollection();
    }

    // Update watchlist
    final watchlistIndex = _watchlist.indexWhere((c) => _sameCard(c, oldCard));
    if (watchlistIndex != -1) {
      final properties = Map<String, dynamic>.from(
        _watchlist[watchlistIndex].propertiesHash,
      );
      _watchlist[watchlistIndex] = newCard.copyWith(propertiesHash: properties);
      _saveWatchlist();
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
    _collectionGroups[index] =
        _collectionGroups[index].copyWith(title: newTitle);
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
    _watchlistGroups[index] =
        _watchlistGroups[index].copyWith(title: newTitle);
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
}