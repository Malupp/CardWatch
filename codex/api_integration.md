# Skill: Integrazione API — CardTrader & Scryfall

## CardTrader API

### Autenticazione
Il token personale viene caricato da `.env` tramite `flutter_dotenv`:
```dart
final token = dotenv.env['CARDTRADER_TOKEN']!;
```

Il file `.env` NON va mai committato. Aggiungilo a `.gitignore`.

### Endpoint principali usati
| Endpoint | Scopo |
|----------|-------|
| `GET /blueprints/export` | Lista blueprint (carte) per nome |
| `GET /marketplace/products` | Offerte di mercato per blueprint ID |

### Struttura risposta marketplace
Ogni offerta ritorna un oggetto con:
- `user.username` — venditore
- `expansion.name_en`, `expansion.code`, `expansion.id`
- `price.formatted` — es. `"1,50 €"`
- `properties_hash` — oggetto libero con condizione, lingua, foil, immagini
- `quantity`

### Parsing del prezzo
```dart
double _parsePrice(String formatted) {
  final cleaned = formatted
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '')
      .trim();
  return double.tryParse(cleaned) ?? double.infinity;
}
```

### Aggiungere nuovi campi da CardTrader
1. Aggiorna il modello `CardMarketplace` con il nuovo campo
2. Aggiorna `fromJson` per estrarlo dalla risposta
3. Aggiorna `_toJson` in `LocalStorage` per persistere il campo
4. Aggiorna `SavedCardsList` / tile se va mostrato in UI

---

## Scryfall API

Base URL: `https://api.scryfall.com`
Nessuna autenticazione richiesta. Rate limit: max 10 req/sec, rispetta i delay.

### Endpoint usati
| Endpoint | Scopo |
|----------|-------|
| `GET /cards/search?q=...` | Ricerca carte per nome |
| `GET /sets/{code}` | Info su un'espansione |

### Dati Scryfall disponibili per filtri avanzati
Dalla risposta di `/cards/search` puoi estrarre:
- `colors` — array es. `["W","U","B","R","G"]`
- `color_identity` — identità colore per Commander
- `rarity` — `common`, `uncommon`, `rare`, `mythic`
- `cmc` — mana value (converted mana cost) come numero
- `type_line` — es. `"Creature — Human Wizard"`
- `oracle_text` — testo regole
- `image_uris.normal` — URL immagine

### Mappatura colori per UI
```dart
const colorMap = {
  'W': ('Bianco', Colors.yellow[100]),
  'U': ('Blu', Colors.blue),
  'B': ('Nero', Colors.black),
  'R': ('Rosso', Colors.red),
  'G': ('Verde', Colors.green),
};
// Incolore = carta senza colori nell'array
```

### Come arricchire una carta con dati Scryfall
```dart
// Cerca per nome esatto
final scryfallCard = await ScryfallApi.getCardByName(card.propertiesHash['name']);

// Aggiungi i dati alle properties della carta
final enriched = card.copyWith(propertiesHash: {
  ...card.propertiesHash,
  'colors': scryfallCard.colors,
  'rarity': scryfallCard.rarity,
  'cmc': scryfallCard.cmc,
  'type_line': scryfallCard.typeLine,
});
```

### Integrazione diretta CardTrader (OAuth)
Per collegare l'app all'account CardTrader dell'utente:
1. CardTrader supporta OAuth2 — vedi `skills/backend.md` per i dettagli
2. Richiede un redirect URI, quindi serve almeno un backend minimo o deep link
3. Con il token OAuth puoi fare ordini, vedere il proprio stock, ecc.
4. Senza OAuth, puoi solo leggere il marketplace pubblico con il token personale