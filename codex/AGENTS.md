# CardWatch — Codex Agent Guide

## What is this project
CardWatch is a Flutter app for Magic: The Gathering collectors and players.
It has 5 sections:

- **Home** — search cards on CardTrader marketplace
- **Collection** — cards you own; track their current market value in case you want to sell
- **Watchlist** — cards you want to buy; set price thresholds and get notified when prices drop
- **Draft** — bulk search cards across expansions (needs improvements, see `skills/features.md`)
- **Profile** — API status, background check settings, tracked portfolio value

## Current state
- Price monitoring and threshold alerts work; background notifications need fixing on some devices
- No groups yet in Collection or Watchlist
- No deck builder yet
- No backend — everything is local via `shared_preferences`

## Tech stack
- **Flutter** (Dart), Material 3
- **State management**: `provider` + `ChangeNotifier`
- **Local storage**: `shared_preferences` via `LocalStorage` singleton (extends ChangeNotifier)
- **Notifications**: `flutter_local_notifications` + `workmanager` for background tasks
- **APIs**: CardTrader REST API (personal token via `.env`), Scryfall REST API (no auth)

## Folder structure
```
lib/
  models/         # CardMarketplace, CarouselItem, and future: CardGroup, Deck, PriceSnapshot
  pages/          # One file per screen
  services/       # LocalStorage, MarketplaceService, ScryfallApi, PriceAlertService, NotificationService
  widgets/        # SavedCardsList, AppDrawer, CarouselWidget, CardDetailDialog
codex/
  AGENTS.md       # This file
  progress.md     # Work tracker: update this whenever Codex changes code or plans work
  *.md            # Topic-specific guides
```

## Hard rules for Codex
1. All global state changes go through `LocalStorage` methods followed by `notifyListeners()` — never mutate lists directly from outside
2. `context.watch<T>()` only inside `build()` — use `context.read<T>()` inside callbacks and methods
3. Always add `if (!mounted) return;` after every `await` in a widget
4. Never commit `.env` — the CardTrader token must stay out of version control
5. Do not introduce new dependencies without adding them to `pubspec.yaml` and documenting them here
6. Keep `codex/progress.md` updated whenever work starts, finishes, or a planned task changes status

## Skills index
| File | Topic |
|------|-------|
| `architecture.md` | Provider, LocalStorage, state patterns |
| `api_integration.md` | CardTrader API, Scryfall API, OAuth plan |
| `features.md` | Groups, deck builder, draft, price snapshots, game tools |
| `distribution.md` | APK, IPA, API token handling for public release |
| `Backend.md` | When and how to introduce a backend |
| `progress.md` | Current status, decisions, and next work queue |
