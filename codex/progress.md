# CardWatch Progress

Last updated: 2026-05-15

## Working rule
- Update this file whenever Codex starts or completes meaningful work.
- Keep statuses short and practical: `Done`, `In progress`, `Planned`, `Blocked`, `Needs investigation`.
- Do not store secrets, tokens, or `.env` values here.

## Current verified state

| Area | Status | Notes |
|------|--------|-------|
| Local Codex instructions | Done | Read `codex/AGENTS.md`, `features.md`, `api_integration.md`, `Backend.md`, and checked the current Flutter files. |
| Work tracker | Done | Added this file and linked it from `codex/AGENTS.md`. |
| Codex docs cleanup | Done | Fixed stale `AGENTS.md` paths, aligned API env names/endpoints with current code, and restored `architecture.md` as architecture notes. |
| Collection/watchlist persistence | Done | Uses `shared_preferences` through `LocalStorage`; state changes call storage methods and `notifyListeners()`. |
| Collection/watchlist groups | Done | Storage and UI are connected in Collection and Watchlist: create/rename/delete groups, filter by group, and assign cards via long press. |
| Runtime stability fixes | Done | Removed storage mutations from `setState` closures in saved cards UI and removed `setState` calls from image builders that could dirty widgets during build. |
| Watchlist price threshold alerts | Done | Watchlist cards can store `priceThresholdEur`; `PriceAlertService` checks thresholds. |
| Draft search by set | Done | `DraftPage` loads Scryfall sets, loads cards by set, and filters by card name. |
| Draft advanced filters | Done | `DraftPage` now filters by color, rarity, mana value, type, and card name. |
| Scryfall data for filters | Done | `CardModel` stores `colors`, `rarity`, and `cmc` for Draft; `LocalStorage` enriches saved collection/watchlist cards with Scryfall metadata after add. |
| CardTrader marketplace lookup | Done | Diagnostics confirmed token/base URL and live endpoints work. Added throttling/retry for `/marketplace/products` to reduce rate-limit failures during broad searches. |
| Price snapshots | Done | Added local `PriceSnapshot` model/storage in `shared_preferences`; snapshots are saved on add, manual refresh, refresh-all, and background checks. |

## Requested improvements queue

| Priority | Task | Status | Next step |
|----------|------|--------|-----------|
| P1 | Make Draft more useful with Scryfall filters: color, rarity, mana value, type | Done | Added filter state/UI to `DraftPage`; `CardModel` now retains Scryfall fields needed by Draft. |
| P1 | Investigate CardTrader "no offers available" | Done | Confirmed `/info`, `/blueprints?name=...`, and `/marketplace/products` work with current `.env`; added service-level marketplace throttling and one retry on 429. |
| P2 | Persist Scryfall metadata on saved cards | Done | `LocalStorage` enriches newly saved cards with Scryfall metadata and persists it in `propertiesHash`. |
| P2 | Add price snapshots | Done | Added model + `LocalStorage` JSON map, saving snapshots on add and price refresh/check. |
| P3 | Show price delta in saved card UI | Done | `SavedCardsList` shows first/current snapshot delta when at least two snapshot days exist. |

## Decisions

- Price snapshots do not require a backend for local-only personal use.
- Start snapshots in local storage; migrate later only if the app needs long history, multi-device sync, OAuth, or server-side notifications.
- Keep CardTrader token handling in `.env`; never write token values into docs or code.
