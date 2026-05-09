# Skill: Planned Features

## 1. Card Groups (Collection & Watchlist)

Groups let users organize cards into named buckets within Collection and Watchlist.

### Model — `lib/models/card_group.dart`
```dart
class CardGroup {
  final String id;           // UUID generated at creation
  final String title;
  final List<String> cardKeys; // unique card identifiers

  CardGroup({required this.id, required this.title, required this.cardKeys});

  factory CardGroup.fromJson(Map<String, dynamic> json) => CardGroup(
    id: json['id'],
    title: json['title'],
    cardKeys: List<String>.from(json['cardKeys']),
  );

  Map<String, dynamic> toJson() => ({
    'id': id,
    'title': title,
    'cardKeys': cardKeys,
  });
}
```

### Card unique key
```dart
String cardKey(CardMarketplace card) =>
    '${card.expansion.nameEn}__${card.user.username}';
```

### LocalStorage additions
```dart
final List<CardGroup> _collectionGroups = [];
final List<CardGroup> _watchlistGroups = [];

// SharedPreferences keys: 'collection_groups', 'watchlist_groups'

void addGroup(String title, {required bool isWatchlist}) { ... notifyListeners(); }
void renameGroup(String id, String newTitle, {required bool isWatchlist}) { ... }
void deleteGroup(String id, {required bool isWatchlist}) { ... }
void addCardToGroup(String groupId, CardMarketplace card, {required bool isWatchlist}) { ... }
void removeCardFromGroup(String groupId, CardMarketplace card, {required bool isWatchlist}) { ... }
```

### Suggested UI
- Horizontal filter chips above the card list to filter by group
- FAB or context menu to create / rename / delete groups
- Long press on a card to assign it to a group

---

## 2. Deck Builder

Decks can live in the Draft section or in a dedicated section.

### Models — `lib/models/deck.dart`
```dart
class Deck {
  final String id;
  final String title;
  final String format;        // 'standard', 'modern', 'commander', 'draft', etc.
  final List<DeckEntry> entries;
  final DateTime createdAt;
}

class DeckEntry {
  final CardMarketplace card;
  final int quantity;
  final bool isSideboard;
}
```

### Useful Draft features to add
- **Add to deck directly from search results** — "+" button in ResultsPage
- **Mana curve** — bar chart with cmc 0–7+ using Scryfall data
- **Color breakdown** — colored counters or pie chart
- **Format legality check** — use `legalities` from Scryfall
- **Export** — plain text format `4x Lightning Bolt` for import in other tools

---

## 3. Advanced Filters with Scryfall Data

These filters apply to both ResultsPage and SavedCardsList.

### Filter state to add
```dart
List<String> _selectedColors = [];  // e.g. [], ['W'], ['U','G']
String? _selectedRarity;            // 'common','uncommon','rare','mythic'
double? _minCmc;
double? _maxCmc;
String? _selectedType;              // 'Creature', 'Instant', 'Sorcery', etc.
```

### Prerequisite
Cards must have `colors`, `rarity`, `cmc`, `type_line` stored in `propertiesHash`.
Enrich them with Scryfall when adding to collection/watchlist (see `api_integration.md`).

### Color selector widget
```dart
Wrap(
  children: ['W','U','B','R','G'].map((color) =>
    FilterChip(
      label: Text(colorMap[color]!),
      selected: _selectedColors.contains(color),
      onSelected: (selected) => setState(() {
        selected
            ? _selectedColors.add(color)
            : _selectedColors.remove(color);
      }),
    )
  ).toList(),
)
```

---

## 4. Price Snapshots

### Do I need a database?
- **Local only, personal use**: no — `shared_preferences` with a JSON map is enough
- **Long history or multi-device sync**: yes — use SQLite (`sqflite`) or a backend

### Model — `lib/models/price_snapshot.dart`
```dart
class PriceSnapshot {
  final DateTime date;
  final double priceEur;

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) => PriceSnapshot(
    date: DateTime.parse(json['date']),
    priceEur: (json['price'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => ({
    'date': date.toIso8601String(),
    'price': priceEur,
  });
}
```

SharedPreferences key: `price_snapshots`
Structure: `Map<String, List<PriceSnapshot>>` where key = `cardKey(card)`

### When to save a snapshot
1. When the card is added to collection or watchlist
2. On every background price check (in `PriceAlertService`)
3. Manually via a "Refresh price" button

### Displaying the delta
```dart
final firstPrice = snapshots.first.priceEur;
final currentPrice = snapshots.last.priceEur;
final delta = currentPrice - firstPrice;
final deltaPercent = (delta / firstPrice) * 100;

Text(
  '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(2)} € '
  '(${deltaPercent.toStringAsFixed(1)}%)',
  style: TextStyle(color: delta <= 0 ? Colors.green : Colors.red),
)
```

### Storage estimate
~50 bytes per snapshot. 100 cards × 365 days = ~1.8 MB.
If you plan a long history, migrate to `sqflite` before hitting SharedPreferences limits.

---

## 5. Magic Game Tools (planned)

Utility tools for playing Magic, to be added as a dedicated section or overlay:

- **Life counter** — two or more players, tap to increment/decrement
- **Poison counters** — per player
- **Commander damage** — matrix per player pair (for Commander format)
- **Turn/phase tracker**
- **Dice roller** — d6, d20, coin flip

These are stateless UI tools — no persistence needed, just local widget state.