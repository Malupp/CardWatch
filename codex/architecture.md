# Skill: API Integration — CardTrader & Scryfall

## CardTrader API

### Authentication
The personal token is loaded from `.env` via `flutter_dotenv`:
```dart
final token = dotenv.env['CARDTRADER_TOKEN']!;
```
Never commit `.env`. It must be in `.gitignore`.

### Endpoints in use
| Endpoint | Purpose |
|----------|---------|
| `GET /blueprints/export` | Search cards by name, returns blueprint list |
| `GET /marketplace/products` | Active listings for a given blueprint ID |

### Response structure (marketplace)
Each listing contains:
- `user.username` — seller
- `expansion.name_en`, `expansion.code`, `expansion.id`
- `price.formatted` — e.g. `"1,50 €"`
- `properties_hash` — free object: condition, language, foil, image URLs
- `quantity`

### Price parsing
```dart
double _parsePrice(String formatted) {
  final cleaned = formatted
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '')
      .trim();
  return double.tryParse(cleaned) ?? double.infinity;
}
```

### Adding new fields from CardTrader
1. Update the `CardMarketplace` model with the new field
2. Update `fromJson` to extract it from the response
3. Update `_toJson` in `LocalStorage` to persist it
4. Update UI widgets if the field needs to be displayed

---

## Scryfall API

Base URL: `https://api.scryfall.com` — no authentication required.
Rate limit: max 10 req/sec. Always add a small delay between bulk requests.

### Endpoints in use
| Endpoint | Purpose |
|----------|---------|
| `GET /cards/search?q=...` | Search cards by name |
| `GET /sets/{code}` | Info about a set/expansion |

### Fields available for advanced filters
From `/cards/search` responses:
- `colors` — array, e.g. `["W","U"]`
- `color_identity` — for Commander
- `rarity` — `"common"`, `"uncommon"`, `"rare"`, `"mythic"`
- `cmc` — mana value as a number
- `type_line` — e.g. `"Creature — Human Wizard"`
- `oracle_text` — rules text
- `image_uris.normal` — card image URL
- `legalities` — map of format → legal/not_legal/banned/restricted

### Color mapping for UI
```dart
const colorMap = {
  'W': 'White',
  'U': 'Blue',
  'B': 'Black',
  'R': 'Red',
  'G': 'Green',
};
// Colorless = card with empty colors array
```

### Enriching a card with Scryfall data
When adding a card to collection or watchlist, optionally fetch Scryfall data
and store it in `propertiesHash` so filters work offline:
```dart
final scryfallCard = await ScryfallApi.getCardByName(card.propertiesHash['name']);

final enriched = card.copyWith(propertiesHash: {
  ...card.propertiesHash,
  'colors': scryfallCard.colors,
  'rarity': scryfallCard.rarity,
  'cmc': scryfallCard.cmc,
  'type_line': scryfallCard.typeLine,
});
```

---

## CardTrader OAuth (planned — direct account integration)

To let users connect their own CardTrader account:
1. CardTrader supports OAuth2 — requires a registered redirect URI
2. This means either a minimal backend or a Flutter deep link handler
3. With OAuth, the app can access the user's personal stock, orders, and wishlist
4. Without OAuth (current state), only the public marketplace is accessible using the personal dev token

See `backend.md` for the implications of adding a backend to support OAuth.