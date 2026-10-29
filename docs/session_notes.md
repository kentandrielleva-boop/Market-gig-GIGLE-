# Session Notes — Supabase Swap

Date: 2026-08-13

## Session summary

Swapped the listing domain from the local Drift implementation
(`LocalListingRepository`) to a Supabase-backed implementation using
`supabase_flutter`. Chat, messages, and profile remain on Drift.

## Decisions

- **Backend:** hosted Supabase project (URL + publishable/anon key supplied by the user)
- **Auth:** anonymous sign-in via `auth.uid()`; swipe state and "My Listings" are scoped per user
- **Seed data:** pushed to Supabase via a Dart script (dev tool only) — **removed** (`tool/seed_supabase.dart` and `lib/data/mock/seed_data.dart` deleted; app now starts empty)
- **Fallback:** fully replaced for listings; `ChatRepository` and `ProfileRepository` stay on Drift

## Changes by file

- `supabase/migrations/0001_initial.sql`
  - New schema for `listings` and `listing_swipes` tables (mirrors the Drift tables)
  - RLS policies: feed readable by all; insert/update restricted to `owner_id = auth.uid()`; swipes fully user-scoped
  - Realtime publication for both tables (required for `.stream(primaryKey: ...)`)
  - `replica identity full` so DELETE events carry full rows and swipe removal streams correctly

- `lib/data/repositories/supabase_listing_repository.dart` (new)
  - `SupabaseListingRepository implements ListingRepository`
  - Realtime streams for feed, saved, passed, and my-listings
  - Feed/saved/passed derived by combining the listings and swipe streams in Dart (Supabase realtime cannot JOIN)
  - Swipe actions via upsert on `(listing_id, user_id)` and delete
  - `createListing` writes `owner_id = auth.uid()` (ignores the hardcoded model default)

- `lib/core/providers/app_providers.dart`
  - Added `supabaseClientProvider` and `currentUserIdProvider`
  - `listingRepositoryProvider` now returns `SupabaseListingRepository`
  - Chat/Profile providers unchanged

- `lib/main.dart`
  - `Supabase.initialize` + `signInAnonymously()` before `runApp`
  - Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` (originally via `--dart-define`, later hardcoded at the top of the file)
  - Still opens the Drift database for chat/profile
  - Generalized the startup error screen text

- `tool/seed_supabase.dart` (new) — **deleted** (sample seed removed; app now starts empty)
  - Pure-Dart script that upserted all 50 `SeedData.listings()` into Supabase
  - Used the service-role key (bypasses RLS) with a fixed sentinel owner id; never ship that key in the app
  - `supabase` package added as a `dev_dependency` so it ran via `dart run`

- `test/widget_test.dart`
  - Overrides `listingRepositoryProvider` with `LocalListingRepository(db)` so the widget test stays offline

- `README.md`
  - Replaced the "Phase 2 (not implemented)" note with real backend setup, run, and seed instructions

- `pubspec.yaml`
  - Added `supabase: ^2.16.0` to dev dependencies

## Running the app

Apply the migration to the hosted project (SQL editor or `supabase db push` after linking).

The URL and key are hardcoded at the top of `lib/main.dart`:

```dart
const supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
const supabaseAnonKey = 'YOUR-PUBLISHABLE-KEY';
```

Then run normally:

```bash
flutter run
```

Note: the publishable key is the same value as the anon key (Supabase renamed it in the SDK; `anonKey` is deprecated in `supabase_flutter` 2.17.1). Hardcoding is fine for development; prefer `--dart-define` for released builds.

### Seed the demo listings (removed)

> **Removed.** `tool/seed_supabase.dart` and `lib/data/mock/seed_data.dart` were deleted — app now starts empty.

```bash
# Previously:
# $env:SUPABASE_URL="https://<ref>.supabase.co"
# $env:SUPABASE_SERVICE_ROLE_KEY="<your_service_role_key>"
# dart run tool/seed_supabase.dart
```

## Verification

- `flutter analyze` — no issues
- `flutter test` — all 2 tests pass

## Commit message

```
feat: back listings with Supabase instead of local Drift

Replace LocalListingRepository with SupabaseListingRepository backed
by supabase_flutter. Listings and swipe state live in Supabase tables
with RLS scoped to auth.uid(); the app signs in anonymously on startup.

- Add Supabase schema migration (listings, listing_swipes, RLS,
  realtime, replica identity full)
- Add SupabaseListingRepository with realtime feed/saved/passed
  streams, swipe actions, and create listing
- Wire listingRepositoryProvider to Supabase via supabaseClient and
  currentUserId providers; chat/profile stay on Drift
- Initialize Supabase with URL/publishable key in main.dart
- Add tool/seed_supabase.dart script to push the 50 seed listings
- Override listing repository in widget tests to stay offline
- Update README with backend setup, run, and seed instructions
```

## App icon location

Launcher icon PNGs (one per density):

```
android/app/src/main/res/mipmap-mdpi/ic_launcher.png     (48×48)
android/app/src/main/res/mipmap-hdpi/ic_launcher.png     (72×72)
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png    (96×96)
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png   (144×144)
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png  (192×192)
```

No adaptive icon setup exists (no `mipmap-anydpi-v26` XML or `ic_launcher_round`). `drawable/launch_background.xml` is the splash background, not the app icon.
