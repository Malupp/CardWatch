# CardWatch 🃏

A Flutter app for Magic: The Gathering collectors and players.
Search cards on CardTrader, track prices, monitor your collection and wishlist, and get notified when a price drops below your threshold.

> ⚠️ This project is in active development. Some features listed below are planned or in progress.

---

## Features

### Current
- **Search** cards by name via CardTrader marketplace
- **Collection** — save cards you own, monitor their current market value
- **Watchlist** — save cards you want to buy, set price alert thresholds
- **Draft** — search cards across multiple expansions in bulk
- **Profile** — view tracked value, API status, manage background price checks
- **Price alerts** — background worker checks prices and sends local notifications when a card drops below threshold
- **Filters** — filter by set, condition, foil, language, max price

### Planned
- Card groups with custom titles (in Collection and Watchlist)
- Deck builder with mana curve, color breakdown, format legality
- Draft improvements with Scryfall filters (color, rarity, mana value, card type)
- Price snapshots — save price at add time and track changes over days
- Magic game tools — life counter, poison counters, other in-game mechanics
- Direct CardTrader account integration via OAuth
- Public APK / IPA distribution

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State management | `provider` + `ChangeNotifier` |
| Local storage | `shared_preferences` |
| Background tasks | `workmanager` |
| Notifications | `flutter_local_notifications` |
| APIs | CardTrader REST, Scryfall REST |

---

## Project Structure

```
lib/
  models/       # Data models (CardMarketplace, Deck, ecc.)
  pages/        # One file per screen
  services/     # LocalStorage, MarketplaceService, ScryfallApi, PriceAlertService
  widgets/      # Reusable UI components
codex/
  AGENTS.md     # Codex agent guide
  skills/       # Topic-specific guides for AI-assisted development
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- A CardTrader account with a personal API token

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/cardwatch.git
cd cardwatch
flutter pub get
```

Create a `.env` file in the project root:

```env
CARDTRADER_TOKEN=your_personal_token_here
```

> ⚠️ Never commit `.env`. It is already in `.gitignore`.

```bash
flutter run
```

### Build

```bash
# Android
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ipa
```

---

## API Token Note

Currently the app uses a personal CardTrader API token stored in `.env`.
This is fine for personal use and development, but **must not be bundled in a public release build**.
See `codex/skills/distribution.md` for the planned approach to handle this for public distribution.

---

## Known Issues

- Push notifications from background price checks do not always fire automatically on some devices — manual trigger works correctly
- iOS background execution is limited by the OS; Workmanager behavior may differ from Android

---

## Roadmap

See the [planned features](#planned) section above. Contributions and suggestions are welcome via Issues.

---

## License

MIT