import '../models/card_marketplace.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal() {
    _loadData();
  }

  final List<CardMarketplace> _collection = [];
  final List<CardMarketplace> _watchlist = [];

  List<CardMarketplace> get collection => List.unmodifiable(_collection);
  List<CardMarketplace> get watchlist => List.unmodifiable(_watchlist);

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionJson = prefs.getStringList('collection') ?? [];
    final watchlistJson = prefs.getStringList('watchlist') ?? [];
    _collection.clear();
    _collection.addAll(collectionJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))));
    _watchlist.clear();
    _watchlist.addAll(watchlistJson.map((e) => CardMarketplace.fromJson(jsonDecode(e))));
  }

  Future<void> _saveCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _collection.map((c) => jsonEncode(_toJson(c))).toList();
    await prefs.setStringList('collection', jsonList);
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _watchlist.map((c) => jsonEncode(_toJson(c))).toList();
    await prefs.setStringList('watchlist', jsonList);
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

  void addToCollection(CardMarketplace card) {
    if (!_collection.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username)) {
      _collection.add(card);
      _saveCollection();
    }
  }

  void addToWatchlist(CardMarketplace card) {
    if (!_watchlist.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username)) {
      _watchlist.add(card);
      _saveWatchlist();
    }
  }

  void removeFromCollection(CardMarketplace card) {
    _collection.removeWhere((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
    _saveCollection();
  }

  void removeFromWatchlist(CardMarketplace card) {
    _watchlist.removeWhere((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
    _saveWatchlist();
  }
} 