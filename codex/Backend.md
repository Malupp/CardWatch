# Skill: Backend — When and How to Introduce One

## Do you need a backend right now?

**No**, for the current feature set. Everything works locally:
- Card data comes from CardTrader and Scryfall (external APIs)
- Collection, watchlist, groups, decks, and price snapshots all fit in `shared_preferences` or `sqflite`
- Notifications are local

**You need a backend when:**
- You want price snapshot history synced across devices
- You want to implement CardTrader OAuth (requires a redirect URI on a server)
- You want push notifications from a server (not just local)
- You want an admin panel to manage app-wide data

---

## Minimal backend option (if needed)

A very small backend is enough for most cases. Suggested stack (free tier friendly):

| Layer | Option |
|-------|--------|
| Runtime | Node.js (Express) or .NET minimal API |
| Database | PostgreSQL on Supabase (free tier) or PlanetScale |
| Hosting | Render.com free tier, Railway, or Fly.io |
| Auth | JWT or Supabase Auth |

### What it would handle
1. **CardTrader OAuth flow** — receive the redirect, exchange code for token, return it to the app
2. **Price snapshot storage** — `POST /snapshots`, `GET /snapshots/{cardKey}`
3. **Optional: push notifications** — server-triggered via FCM (Firebase Cloud Messaging)

---

## CardTrader OAuth flow (planned)

```
App → opens CardTrader OAuth URL in browser
CardTrader → redirects to your backend /oauth/callback?code=...
Backend → exchanges code for access token
Backend → returns token to app (via deep link or response)
App → stores token in flutter_secure_storage
App → uses token for all CardTrader requests
```

### Flutter deep link setup
```yaml
# android/app/src/main/AndroidManifest.xml
# Add intent-filter for your scheme: cardwatch://oauth/callback
```

This avoids needing a full backend if you only need OAuth —
the backend can be a single serverless function.

---

## Database schema (if you add one)

### price_snapshots
```sql
CREATE TABLE price_snapshots (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  card_key TEXT NOT NULL,       -- expansion.nameEn + '__' + user.username
  price_eur DECIMAL(10,2),
  recorded_at TIMESTAMP DEFAULT NOW()
);
```

### decks (if synced)
```sql
CREATE TABLE decks (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT,
  format TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE deck_entries (
  id SERIAL PRIMARY KEY,
  deck_id UUID REFERENCES decks(id),
  card_key TEXT,
  quantity INT,
  is_sideboard BOOLEAN DEFAULT FALSE
);
```

---

## Recommendation

Start without a backend. Implement price snapshots locally with `sqflite`.
Add a backend only when you need OAuth or cross-device sync.
When you do, keep it minimal — a few endpoints on Render.com free tier is enough.