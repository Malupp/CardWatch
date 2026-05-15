# Skill: Architecture

## App structure

CardWatch is a Flutter app organized around Material pages, provider state,
and small services.

Current main folders:
- `lib/pages/` contains screen-level widgets such as Home, Collection, Watchlist, Draft, Profile.
- `lib/widgets/` contains shared UI such as `SavedCardsList`, navigation, card tiles, detail dialogs.
- `lib/services/` contains API, persistence, notifications, and price alert logic.
- `lib/models/` contains app data objects such as marketplace cards, Scryfall details, groups.

## State management

Global user state lives in `LocalStorage`, a singleton `ChangeNotifier`.
Use `Provider` to expose it to widgets.

Rules:
- Read reactive state with `context.watch<LocalStorage>()` inside `build()`.
- Use `context.read<LocalStorage>()` inside callbacks, handlers, and async methods.
- Do not mutate returned lists directly; getters return unmodifiable copies.
- Add or change global state through `LocalStorage` methods, then call `notifyListeners()`.

## Persistence

Current persistence uses `shared_preferences`.

Stored areas:
- `collection`
- `watchlist`
- `collection_groups`
- `watchlist_groups`
- price alert settings in `PriceAlertService`

Planned persistence:
- `price_snapshots`: local JSON map in `shared_preferences` first.
- Move to SQLite or backend only when history becomes large or needs sync.

## Saved card flow

`SavedCardsList` renders both collection and watchlist cards.
`WatchlistPage` passes:
- `cards: () => storage.watchlist`
- `onRemove: storage.removeFromWatchlist`
- `onSetPriceThreshold: storage.setWatchlistPriceThreshold`

Collection should follow the same pattern where possible, with page-specific
callbacks passed into shared widgets instead of branching inside storage.

## API service boundaries

`MarketplaceService` owns CardTrader HTTP calls.
`ScryfallApi` owns Scryfall HTTP calls.
`UnifiedCardService` combines saved-card data, Scryfall details, and marketplace offers.
`PriceAlertService` owns refresh/check logic and background alert scheduling.

Do not call HTTP directly from UI unless the existing page already does so and the
change is very small. Prefer adding a service method.

## Async widget rules

After every `await` in a stateful widget method, check:
```dart
if (!mounted) return;
```

This is especially important in pages that open dialogs, bottom sheets, snackbars,
or navigate after async API calls.

## Adding a new feature

1. Put durable user data in `LocalStorage` first.
2. Add/extend a model only if the data has structure beyond a simple UI flag.
3. Keep API parsing in services or model factories.
4. Update shared UI widgets only when the behavior applies to both collection and watchlist.
5. Update `codex/progress.md` with the new status before finishing.
