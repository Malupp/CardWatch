import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_marketplace.dart';

class LocalStorage extends ChangeNotifier {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal() {
    _loadData();
  }

  final List<CardMarketplace> _collection = [];
  final List<CardMarketplace> _watchlist = [];

  List<CardMarketplace> get collection => List.unmodifiable(_collection);
  List<CardMarketplace> get watchlist => List.unmodifiable(_watchlist);

  // ---------------------------------------------------------------------------
  // Load / Save
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionJson = prefs.getStringList('collection') ?? [];
    final watchlistJson = prefs.getStringList('watchlist') ?? [];

    _collection.clear();
    _collection.addAll(
      collectionJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))),
    );

    _watchlist.clear();
    _watchlist.addAll(
      watchlistJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))),
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _sameCard(CardMarketplace a, CardMarketplace b) =>
      a.expansion.nameEn == b.expansion.nameEn &&
      a.user.username == b.user.username;
}