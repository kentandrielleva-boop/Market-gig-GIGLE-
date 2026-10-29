# Session Notes — Free-Plan Footprint Optimizations

Date: 2026-08-14

## Session summary

Audited the Supabase integration against the free-plan caps (500 MB DB, 5 GB
egress/mo, 2M realtime messages/mo, 200 concurrent connections) and optimized
the realtime layer and schema for a low footprint. The main problem was
realtime subscription sprawl: every screen opened its own `postgres_changes`
subscription, so feed/saved/passed alone held six subscriptions and a single
listing change was delivered to the same client several times (realtime
messages are metered per delivered message).

## Decisions

- **One channel per table, shared app-wide.** All Supabase-backed screens
  now draw from `SupabaseSharedStreams`, which memoizes one broadcast stream
  per (table, filter). `supabase_flutter`'s `stream()` returns a broadcast
  `SupabaseStreamBuilder` backed by a single `ReplaySubject` + channel, so
  any number of listeners share one subscription and one socket.
- **Push the always-on filter to the server.** The feed's listings channel now
  applies `status = active` server-side (both for the initial postgrest fetch
  and the realtime filter). Dynamic UI filters (category/price/type) stay
  client-side on the bounded list to avoid tearing the channel down on every
  filter toggle.
- **Bound the feed.** The shared active-listings channel uses
  `order('created_at', descending) + limit(feedWindowSize = 100)`. This caps
  the initial fetch, the emitted list, and client memory. Realtime still
  streams inserts/updates (inherent to the SDK), but the emitted window stays
  capped.
- **Saved/passed over REST, not full-table realtime.** Saved/passed now
  resolve listing details with a single bounded `inFilter` REST request each
  time the (shared, user-scoped) swipe channel changes. This keeps them
  accurate for listings of any age — including ones older than the feed window
  — without a second full-table subscription.
- **Profile ratings denormalized.** `rating_avg` / `rating_count` live on
  `profiles` and are maintained by a database trigger, so the header reads one
  row instead of folding every review on every realtime event. The raw
  reviews stream remains only for the reviews tab.
- **`rater_name` filled by a database trigger.** The client no longer does a
  `select('name')` round-trip before every review write.
- **Replica identity narrowed where possible.** Only `profiles` (filtered on
  its primary key) moved to the default replica identity; `listings`,
  `listing_swipes`, and `reviews` keep `replica identity full` because they
  are filtered on non-primary-key columns and must match DELETE events
  server-side.
- **Dead columns removed.** `listings.view_count` / `save_count` were never
  written by the app; dropped from the schema, the domain model, the Drift
  local table, the seed tool, and the My-Listings UI.

## Changes by file

- `supabase/migrations/0003_footprint.sql` (new)
  - Drops `view_count` / `save_count` from `listings`
  - `profiles` → default replica identity
  - Adds `profiles.rating_avg` / `rating_count` + `update_profile_rating()`
    trigger (insert/update/delete on `reviews`) + backfill
  - Adds `fill_review_rater_name()` BEFORE INSERT trigger on `reviews`

- `lib/data/repositories/supabase_shared_streams.dart` (new)
  - `SupabaseSharedStreams`: memoized broadcast channels — `activeListings`
    (status-filtered, ordered, limited), `myListings` (owner-scoped),
    `mySwipes` (user-scoped), `profileRows` (PK-filtered), `reviewRows`
  - `feedWindowSize = 100`

- `lib/data/repositories/stream_utils.dart` (new)
  - Hand-rolled `combineLatest2` (extracted from the old listing repository;
    avoids adding rxdart)

- `lib/data/repositories/supabase_listing_repository.dart`
  - Constructor now takes `SupabaseSharedStreams`
  - `watchFeed` combines `activeListings` + `mySwipes` (hides already-swiped)
  - `watchSaved` / `watchPassed` resolve listings via REST `inFilter` from the
    shared swipe channel
  - `watchMyListings` reads the shared owner-scoped channel
  - `_listingFromRow` / `_listingToRow` no longer carry view/save counts

- `lib/data/repositories/supabase_profile_repository.dart`
  - Constructor now takes `SupabaseSharedStreams`
  - `watchProfile` combines `profileRows` + `myListings` and reads rating
    aggregates from the row (no review folding)
  - `addReview` no longer fetches the rater name (DB trigger fills it)

- `lib/core/providers/app_providers.dart`
  - New `supabaseSharedStreamsProvider`
  - `listingRepositoryProvider` / `profileRepositoryProvider` pass the shared
    streams into their Supabase repositories

- `lib/main.dart`
  - URL + anon key now come from `--dart-define` (`SUPABASE_URL`,
    `SUPABASE_ANON_KEY`) with placeholder defaults so a bare `flutter run`
    still compiles

- `lib/domain/models/models.dart`
  - `Listing` no longer has `viewCount` / `saveCount`

- `lib/data/local/tables.dart` + regenerated `app_database.g.dart`
  - `ListingsTable` drops the dead `view_count` / `save_count` columns

- `lib/data/local/app_database.dart`
  - Drift mapper no longer reads/writes the removed columns

- `lib/data/mock/seed_data.dart` — **deleted** (sample seed removed; app now starts empty)
  - Seed listings no longer set view/save counts

- `tool/seed_supabase.dart` — **deleted** (sample seed removed)

- `lib/features/profile/profile_screen.dart`
  - Removed the always-zero "N views · N saves" line from My Listings

- `README.md`
  - Notes `0003_footprint.sql`, updated the profile-ratings feature line, and
    added a "Free-tier footprint notes" section

## Footprint impact

- Realtime subscriptions for the listings domain drop from up to six per user
  to three shared ones (active listings, my listings, my swipes); the profile
  domain drops from four to two shared ones (profile, reviews). A single
  table change is now delivered once per user instead of 3–4 times.
- The feed only ever receives active rows and keeps a bounded window, cutting
  both egress and client memory.
- Saved/passed move off a full-table subscription onto cheap REST lookups.
- Profile headers stop re-folding reviews on every realtime event.

## Trade-offs / known limitations

- The SDK's `stream()` keeps an internal cache of all matching rows even when
  `limit()` is set; the *emitted* window is bounded but the in-memory row set
  can still grow over a very long-lived session. For a free-plan MVP this is
  acceptable and documented in code.
- Dynamic feed filters (category/price/type) remain client-side; only the
  static `status` filter is pushed to the server. Pushing dynamic filters
  server-side would recreate the channel on every toggle.
- Saved/passed listing *details* refresh when the swipe set changes (REST),
  not live on every listing edit. Price/description changes outside the feed
  window are picked up on the next swipe change or app start.
- `SupabaseProfileRepository` reuses the shared `myListings` channel for the
  listing count; this assumes the profile being viewed is always the signed-in
  user's own profile (true for the current app).

## Running / verification

- Apply `supabase/migrations/0003_footprint.sql` to the hosted project
  (SQL editor or `supabase db push` after linking).
- `flutter analyze` — no issues
- `flutter test` — all 2 tests pass

## Commit message

```
perf: optimize Supabase realtime footprint for the free plan

- Share one realtime channel per table app-wide (SupabaseSharedStreams);
  feed/saved/passed previously opened six subscriptions, multiplying metered
  realtime messages
- Push status=active filter server-side and bound the feed window
  (order + limit 100) on the active-listings channel
- Resolve saved/passed details over REST inFilter from the shared swipe
  channel instead of a second full-table subscription
- Denormalize profile rating aggregates (rating_avg/rating_count) via a
  database trigger; drop per-event client-side review folding
- Fill review rater_name with a database trigger; drop the client name
  lookup round-trip
- Drop dead view_count/save_count columns (schema, model, Drift, seed, UI);
  narrow profiles to default replica identity
- Read Supabase URL/anon key from --dart-define with placeholder defaults
- Add supabase/migrations/0003_footprint.sql and update README + session docs
```
