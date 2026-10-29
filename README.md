# Marketplace & Gig

Flutter Android app combining a local marketplace with a gig-economy platform. Built with **Material Design 3**, **Riverpod**, **go_router**, **Drift (SQLite)** as a local chat cache, **Firebase** (Auth, Firestore on the free Spark plan) for user profiles, listings, ratings, and realtime chat, and **Cloudinary** for image uploads.

## Features

- **Accounts** — Email/password sign-up & sign-in via Firebase Auth with a **math-captcha** anti-bot check on sign-up/sign-in, **email verification** (verify link, then "I've verified" check, resend), session persistence, and sign-out
- **Home** — Tinder-style swipe discovery feed with tier-aware card stack, filters, and passed-history sheet
- **Post** — Modal bottom sheet to sell items or post gigs with photo upload and validation
- **Inbox** — Searchable conversation list and paginated chat threads (20 messages/page)
- **Saved & Profile** — Saved listings grid, my listings, reviews with star distribution
- **Profile ratings** — Realtime 1–5 star ratings with a "Leave a review" sheet; aggregate rating + review-count are recomputed on the `profiles` doc in a client transaction per review
- **Performance tiers** — High-end devices get dynamic color, card peek, gradient overlays; low-end gets simplified UI

## Requirements

- Flutter 3.16+ (stable)
- Android SDK for device/emulator builds

## Getting started

```bash
cd Projects/marketplace-gig
flutter pub get
dart run build_runner build   # Regenerate Drift code after schema changes
flutter run                   # Launch on connected device/emulator
```

### Design previews (360×800)

```bash
flutter run -t lib/previews/preview_main.dart
```

## Project structure

```
lib/
  core/         # Theme, router, providers, performance tier
  data/         # Drift database (chat cache), repositories (Firebase + local) — sample seed removed, app starts empty
  domain/       # Shared models
  features/     # home, post, inbox, profile, saved, shell
  previews/     # 6 high-fidelity design frames (inline fakes, no shipped dataset)
```

## Firebase backend

Listings, swipes, user auth, profiles, reviews, and chat are backed by
Firebase (Auth, Firestore on the Spark plan) via `FirebaseListingRepository`,
`FirebaseProfileRepository`, and `FirebaseChatRepository` (Firestore as
source of truth, Drift as a local read cache for paged chat). Images
(avatars, listing photos) upload to Cloudinary via
`core/storage/cloudinary_uploader.dart` (unsigned preset, no new dependency).
Firestore rules live in `firestore.rules` (deploy with
`firebase deploy --only firestore:rules,firestore:indexes`). Yes, Spark
stores conversations — `conversations/{id}/messages/{msgId}` are plain
Firestore docs that count toward the free read/write quota. Cloudinary stores
only images/video, not chat data.

Collections:

- `listings/{id}` — type/title/price/description/image_urls/category/location/
  duration/remote_only/status (int enums)/owner_id/rating_sum/rating_count/
  created_at. Non-active listings are readable by the owner and by anyone with
  a chat about them.
- `swipes/{uid}_{listingId}` — user_id/listing_id/action/acted_at
- `reports/{reporterUid}_{listingId}` — listing_id/listing_owner_id/
  reporter_id/reason (int enum)/details/created_at (create-only; review in the
  Firebase console)
- `profiles/{uid}` — name/bio/avatar_url/rating_sum/rating_count/
  terms_accepted_at/terms_version/created_at (older profiles may still carry
  `rating_avg`; the sum then falls back to `round(rating_avg * rating_count)`)
- `reviews/{reviewerUid}_{revieweeUid}` — reviewee_id/reviewer_id/rater_name/
  rating/comment (≤ 500)/listing_title/conversation_id/verified/created_at/
  updated_at/reply (≤ 500)/reply_at
- `listing_reviews/{reviewerUid}_{listingId}` — listing_id/listing_owner_id/
  reviewer_id/rater_name/rating/comment (≤ 500)/listing_title/conversation_id/
  verified/created_at/updated_at/reply (≤ 500)/reply_at

  Review rules (both collections):
  - **One per pair.** The doc id is fixed, so a review is created once and then
    only its author can edit it (not its target or `created_at`) or delete it.
  - **No self-reviews.** Users can't rate themselves or their own listings.
  - **Verified.** A review must cite a thread, `conversation_id`, between the
    reviewer and the reviewed user or listing owner, with at least one message,
    and with no block in either direction. For listings, that thread is
    `{listingId}_{reviewerUid}`.
  - **Tamper-proof aggregates.** Every review write moves `rating_sum`/
    `rating_count` on the profile or listing in the same transaction. The rules
    check that the change is exactly +1 / 0 / −1 and the rating difference.
    Nobody can write an arbitrary average, and owners can't touch their own.
  - **Replies.** The reviewed user or listing owner may set or remove only
    `reply`/`reply_at`.
- `review_reports/{reporterUid}_{kind}_{reviewId}` — review_id/review_kind
  (`user`|`listing`)/reporter_id/reason (int enum)/details/created_at
  (create-only, never about your own review; review in the Firebase console)
- `conversations/{id}/messages/{msgId}` — two kinds of thread:
  - listing threads, id `{listingId}_{buyerUid}`: kind `'listing'`/seller_id/
    listing_id/listing_title/listing_type
  - direct threads, id `dm_{lowUid}_{highUid}`: kind `'direct'`, with
    participant_ids sorted to match the id

  Both carry participant_ids (fixed at creation)/participants.{uid}.{name,avatar}/
  last_message/last_sender_id/updated_at/last_read.{uid}/archived.{uid}. Each
  user may only write their own `last_read`/`archived` key. Messages are
  sender_id/text (1–2000 chars)/sent_at.
- `blocks/{blockerUid}_{blockedUid}` — blocker_id/blocked_id/blocked_name/
  blocked_avatar/created_at. Only the blocker can read or delete it. The chat
  rules refuse new threads and messages between users who blocked each other.
- `user_reports/{reporterUid}_{reportedUid}` — reporter_id/reported_id/reason
  (int enum)/details/conversation_id?/created_at (create-only; review in the
  Firebase console)

### 1. Configure Firebase (once)

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # generates lib/firebase_options.dart + google-services.json
```

Then in the Firebase console: enable **Email/Password** auth, create a
**Firestore** database (Spark plan — no Blaze upgrade needed), and deploy the
rules above. No Firebase Storage bucket needed — images go to Cloudinary:

1. Cloudinary console → Settings → Upload → Upload presets → Add preset.
2. Signing Mode: **Unsigned**. Folder: e.g. `market-gig` (optional).
3. Pass at run time (nothing secret is committed):

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
```

### 2. Run the app

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy   # Launch on device/emulator
```

> VS Code: Run & Debug → **market-gig (Firebase)** (F5). The `Preview`
> config launches `lib/previews/preview_main.dart` without Firebase.

### 3. Captcha & email verification

- Sign-up/sign-in sit behind a local math-captcha
  (`lib/core/auth/captcha_gate.dart` + `captcha.dart`); Firebase Auth has no
  server captcha token, so the gate itself is the anti-bot check. For
  production hardening, enable **App Check** in the console.
- Email verification: sign-up sends the link and signs the user in
  immediately; unverified users are held on `/verify-email` by the router
  guard until they tap the link and press "I've verified my email"
  (`refreshEmailVerified()`). Resend uses the signed-in account.

### 4. Seed the demo listings (removed)

> **Removed.** The app now starts with an empty local Drift database on first launch (no seeded listings, conversations, or profiles). To repopulate for local testing, create listings via the Post sheet or insert docs manually via the Firebase console.

## Testing

```bash
flutter analyze
flutter test
```

Chat and messages start empty on first launch (seed removed). Listings, profiles, and
ratings require a configured Firebase project as described above. Widget tests run
fully offline (Firebase-backed repositories are swapped for the local Drift
implementations).
