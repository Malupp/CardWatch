# Skill: Distribution — APK, IPA, and API Token Handling

## Building for release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

For Play Store:
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (requires macOS + Xcode)
```bash
flutter build ipa --release
# Output: build/ios/ipa/
```

For App Store or TestFlight, open `ios/Runner.xcworkspace` in Xcode and use
the Archive workflow, or use `fastlane` for automation.

---

## The API token problem for public distribution

Currently the CardTrader personal token lives in `.env` and is read at runtime.
This is fine for personal/dev use but **must not be bundled in a public release**.

### Option A — Keep it personal (simplest)
Distribute APK/IPA only to yourself or trusted people.
The `.env` is never in the repo and is manually placed on each build machine.
**Suitable for: personal use, friends, closed beta.**

### Option B — User provides their own token (no backend needed)
Add a settings screen where the user enters their own CardTrader API token.
Store it in `shared_preferences` (or `flutter_secure_storage` for better security).

```dart
// On first launch, show a token setup screen
// Store with flutter_secure_storage
await storage.write(key: 'cardtrader_token', value: enteredToken);

// Read everywhere instead of dotenv
final token = await storage.read(key: 'cardtrader_token');
```

**Suitable for: public release where each user has their own CardTrader account.**

### Option C — Backend proxy (most robust)
A small backend receives API requests from the app, attaches the token server-side,
and forwards them to CardTrader. The token never leaves the server.
See `backend.md` for implementation details.
**Suitable for: production app with a shared token or OAuth flow.**

---

## Recommended approach for CardWatch

Given that CardTrader requires a personal account and token:
**Option B** is the right path for a public release.
Users create a CardTrader account, generate their API token, and paste it in the app settings.
This also sets up the foundation for Option C (OAuth) later.

---

## Platform-specific notes

### Android
- Min SDK: set in `android/app/build.gradle` — check `workmanager` requirements
- Background tasks on Android 12+ require exact alarm permissions
- Workmanager battery optimization: users may need to whitelist the app

### iOS
- Background execution is heavily restricted by iOS
- `workmanager` on iOS fires less reliably than on Android — document this in the app UI
- Push notifications require APNs setup and an Apple Developer account ($99/year)
- TestFlight is the easiest way to distribute to testers before App Store review