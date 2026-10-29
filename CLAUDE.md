# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter (Android) app combining a local marketplace with a gig platform. Package name is `marketplace_gig` (imports use `package:marketplace_gig/...`). Stack: Riverpod 2 (no codegen), go_router, Drift (SQLite), Firebase Auth + Firestore (Spark/free plan), Cloudinary for images.

`docs/` (PROMPT.md, session_notes*.md) describes an earlier **Supabase** backend and is out of date — the app now uses Firebase. Trust the code and README over `docs/`.

## Commands

```bash
flutter pub get
flutter analyze                                   # lints: flutter_lints + prefer_const_*, avoid_print
flutter test                                      # all tests (run fully offline)
flutter test test/radial_menu_test.dart           # single file
flutter test --plain-name "expands a branch"      # single test by name
dart run build_runner build --delete-conflicting-outputs   # after editing Drift tables (lib/data/local/tables.dart)
dart format lib test

# Run (Cloudinary values are compile-time defines; uploads fail without them)
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
flutter run -t lib/previews/preview_main.dart     # design previews, no Firebase needed

firebase deploy --only firestore:rules,firestore:indexes
```

VS Code launch configs in `.vscode/launch.json` already carry the dart-defines.

## Architecture

**Startup** (`lib/main.dart`): `runApp` immediately shows a branded splash; `StartupBootstrap` watches `appDatabaseProvider` (Drift open) and `firebaseInitProvider` and only mounts `MarketplaceApp` once both resolve. Keep heavy I/O out of `main()` — this was done to avoid ANRs on low-end devices.

**Dependency wiring** (`lib/core/providers/app_providers.dart`): the single place where repositories are constructed. Features depend on the abstract `ListingRepository` / `ChatRepository` / `ProfileRepository` interfaces in `lib/data/repositories/repositories.dart`; the Firebase implementations live alongside. `authGatewayProvider` throws while Firebase is initializing, and `currentUserIdProvider` throws when signed out — repository providers depend on it, so they are only valid inside the authenticated shell.

**Data layer**:
- Firestore is the source of truth for listings, swipes, profiles, reviews, and chat. Collection shapes are documented in README.md; security rules in `firestore.rules`.
- Chat uses Firestore for sync but reads through Drift (`FirebaseChatRepository` wraps `LocalChatRepository`) so paging (20/page) is cheap and offline. Sign-out wipes the Drift chat/swipe tables.
- Feed/saved/passed streams are derived by combining listing and swipe streams in Dart (`stream_utils.dart` `combineLatest2`, hand-rolled to avoid rxdart).
- Reviews (`reviews/` for users, `listing_reviews/` for listings) are one per reviewer per target (fixed doc id) and must cite a chat (`conversation_id`). Each write moves the integer aggregate (`rating_sum`/`rating_count` on the profile or listing) in the same transaction (`FirebaseProfileRepository._writeReview`); `firestore.rules` (`aggregateFollowsReview`) rejects any other delta, so keep client math and rules in step. Review UI lives in `features/reviews/review_widgets.dart` (`ReviewsSection`).
- Images go to Cloudinary via an unsigned preset (`core/storage/cloudinary_uploader.dart`), not Firebase Storage.

**Routing** (`lib/core/router/app_router.dart`): one `redirect` enforces, in order: signed-out → `/login`; unverified email → `/verify-email`; Terms/EULA not accepted for the current version → `/legal?gate=true`. A `ValueNotifier` listening to `authSessionProvider`, `emailVerifiedProvider`, and `legalAcceptanceProvider` re-runs it. Loading/error states deliberately *don't* block, to avoid lockout flicker. Authenticated screens live under a `ShellRoute` (`ShellScaffold`: only the floating "Post" button — no bottom nav, the radial home menu is the sole navigation, and system back on any shell screen returns to `/home`. No `SafeArea`/AppBar — screens handle their own status-bar insets).

**Home** is a radial node menu (`features/home/`): `node_data.dart` is the static tree (root → 6 mains → leaves with routes), `node_home_provider.dart` holds expanded/focused/breadcrumb state, `widgets/radial_layout.dart` is the pure layout + camera-fit math, and `NodeHomeScreen` animates between layouts with one `AnimationController`, painting via `NodePainter` (which also exposes per-node semantics). Leaves navigate with `context.go`. The older swipe feed (`HomeScreen`, `SwipeCardStack`) is reached via `/home/discover/*`.

**Performance tiers** (`core/performance/`): `deviceTierProvider` (high/low via `device_info_plus`) gates dynamic color, card peek, gradients, and image cache sizing. Check the tier when adding costly visuals.

**Auth**: `AuthGateway` abstracts Firebase Auth. Sign-up/sign-in pass a local math captcha (`core/auth/captcha_gate.dart`) — Firebase has no server captcha token.

## Testing

Widget tests must not touch Firebase. Follow `test/widget_test.dart`: override `appDatabaseProvider` with an in-memory Drift DB (`NativeDatabase.memory()`), `firebaseInitProvider` with a no-op, `authGatewayProvider` with a fake, and the repository providers with the `Local*Repository` implementations. Semantics-only nodes (e.g. radial menu nodes) are found with `find.semantics.byLabel`, not `find.bySemanticsLabel`.
