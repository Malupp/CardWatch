import '../models/card_marketplace.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  final List<CardMarketplace> _collection = [];
  final List<CardMarketplace> _watchlist = [];

  List<CardMarketplace> get collection => List.unmodifiable(_collection);
  List<CardMarketplace> get watchlist => List.unmodifiable(_watchlist);

  void addToCollection(CardMarketplace card) {
    if (!_collection.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username)) {
      _collection.add(card);
    }
  }

  void addToWatchlist(CardMarketplace card) {
    if (!_watchlist.any((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username)) {
      _watchlist.add(card);
    }
  }

  void removeFromCollection(CardMarketplace card) {
    _collection.removeWhere((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
  }

  void removeFromWatchlist(CardMarketplace card) {
    _watchlist.removeWhere((c) => c.expansion.nameEn == card.expansion.nameEn && c.user.username == card.user.username);
  }
} 