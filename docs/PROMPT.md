# Marketplace & Gig — Refined Build Prompt (v2)

> Self-contained spec for the **Marketplace & Gig** Flutter app. This document
> is the authoritative prompt for building and extending the app. v2 adds
> **user accounts**, **Supabase-backed users & data**, **bot protection
> (captcha) + email verification**, and **profile ratings**. Chat/messages
> intentionally stay on the local Drift database (out of scope for this
> iteration).

## 1. Product context

A local marketplace combined with a gig-economy platform, built as a single
Flutter Android app. Buyers and sellers post items and gigs, discover them via
a Tinder-style swipe feed, message each other, and rate each other's profiles
after transactions.

Design language: **Material Design 3**. State: **Riverpod**. Navigation:
**go_router**. Persistence: **Drift (SQLite)** for chat + messages only.
Backend: **Supabase** (`supabase_flutter`) for **auth, user profiles, listings,
swipe state, and ratings**.

## 2. Tech stack

- Flutter 3.16+ (stable), Dart SDK 3.8+
- `flutter_riverpod`, `go_router`, `drift` + `sqlite3_flutter_libs`
- `supabase_flutter` (current resolved: `^2.17.1`) with `publishableKey`
- `cached_network_image`, `dynamic_color`, `device_info_plus` (perf tiers),
  `image_picker`, `flutter_image_compress`, `infinite_scroll_pagination`,
  `intl`, `uuid`
- Dev: `flutter_lints`, `drift_dev`, `build_runner`, `supabase` (seed script)

## 3. Existing features (keep, unchanged)

- **Home** — swipe feed (`HomeScreen`, `SwipeCardStack`), filters, passed-history
  sheet. Feed/saved/passed derived by combining `listings` + `listing_swipes`
  realtime streams in Dart (Supabase realtime cannot JOIN).
- **Post** — modal bottom sheet (`PostSheet`) to sell items / post gigs, photo
  upload + validation. New listings write `owner_id = auth.uid()`.
- **Inbox** — searchable conversations + paginated Drift chat (20/page).
- **Saved & Profile** — saved grid, my listings, reviews with star distribution.
- **Performance tiers** — high-end devices get dynamic color / card peek /
  gradients; low-end gets the simplified UI.
- `tool/seed_supabase.dart` pushes 50 seed listings with the service-role key
  (dev-only; never ship that key in the app) — **deleted** (sample seed removed; app now starts empty, see README).

## 4. NEW — User accounts & login

Replace the current **anonymous sign-in** (`main.dart` calls
`signInAnonymously()` on startup) with real, persistent **email/password
accounts** backed by Supabase Auth.

Requirements:

1. **Sign-up screen** (`/signup`): email, password (min 8 chars), confirm
   password, display name (optional), and a **captcha** (see §5). Validate
   inputs; show inline errors; disable submit while in-flight.
2. **Sign-in screen** (`/login`): email + password with inline errors; link to
   sign-up; link to resend verification when the account is unconfirmed.
3. **Verify-email screen** (`/verify-email`): shown after sign-up (and after a
   failed sign-in caused by an unconfirmed email). Explains that a confirmation
   link was emailed, offers a **Resend** action, and auto-advances to `/home`
   once the session becomes active (listens to auth changes).
4. **Session persistence** — provided by Supabase (token refresh + storage). No
   manual token handling.
5. **Sign out** — accessible from the Profile screen; returns to `/login`.
6. **Route guard** — `go_router` `redirect` + `refreshListenable`: unauthenticated
   users are redirected to `/login` for all other routes; authenticated users
   are redirected from `/login`, `/signup`, `/verify-email` to `/home`.
7. `currentUserIdProvider` resolves from the authenticated user; listings and
   swipe state remain scoped to `auth.uid()` via existing RLS.
8. Anonymous data (listings/swipes created while signed out) is **discarded** —
   acceptable for this iteration; documented as a known limitation.

## 5. NEW — Bot protection (captcha) & email verification

**Captcha on sign-up (and sign-in):**

- Every sign-up must be gated behind a human-verification challenge so bots
  cannot mass-create accounts.
- The chosen implementation ships a lightweight **math captcha widget**
  (random arithmetic challenge; the solved token is passed through to Supabase).
  This keeps the app runnable without external credentials and demonstrates the
  full wiring.
- For production hardening, **enable hCaptcha in the Supabase Auth dashboard**
  and swap the challenge widget for a real hCaptcha widget; **no app-code change
  is needed** beyond obtaining the hCaptcha token, because the app already
  forwards a `captchaToken` to the Supabase calls:
  - `signUp(email:, password:, data:, captchaToken:)`
  - `signInWithPassword(email:, password:, captchaToken:)`
  - `resend(email:, type: OtpType.signup, captchaToken:)`
- Supabase enforces the token only when hCaptcha is enabled server-side
  (`gotrue_meta_security.captcha_token`); the client always passes it.

**Email verification:**

- Supabase **"Confirm email"** setting enabled (server-side). When it is ON,
  `signUp` returns a user **without** a session → app routes to
  `/verify-email`.
- Sign-in with an unconfirmed account throws an `AuthException`; detect it
  (message/code contains "email not confirmed") and route to `/verify-email`
  instead of showing a generic error.
- The verify-email screen listens to `onAuthStateChange` (PKCE email link flow
  confirms the session on the device) and auto-navigates when
  `session != null`.
- When "Confirm email" is OFF (local/testing), `signUp` returns a session
  immediately → app routes straight to `/home`.

## 6. NEW — Supabase for users & data

Move **users and profile data** off Drift into Supabase. Chat/messages stay on
Drift.

**`profiles` table** (one row per user, auto-created):

```sql
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  avatar_url text,
  bio text not null default '',
  created_at timestamptz not null default now()
);
```

- Auto-provisioned by a `handle_new_user` trigger on `auth.users` insert
  (security definer); `name` defaults from `raw_user_meta_data->>'full_name'`
  or the email prefix; `avatar_url` may stay null (client falls back to the
  existing `picsum.photos/seed/profile/...` placeholder).
- RLS: `select` for everyone (authenticated feed/profiles), `insert`/`update`
  only for the owner (`id = auth.uid()`).
- Add to the `supabase_realtime` publication; `replica identity full`.

**Repository:**

- New `SupabaseProfileRepository implements ProfileRepository` in
  `lib/data/repositories/supabase_profile_repository.dart`.
- `watchProfile()` — combine the `profiles` row stream (`id = <profileOwnerId>`)
  with the `reviews` stream for that user to derive the aggregate rating /
  review count in Dart (same pattern as `SupabaseListingRepository`), plus a
  listings-count stream for `listingsCount`. `memberSince` from
  `profiles.created_at`.
- `watchReviews()` — realtime stream of `reviews` rows where
  `reviewee_id = <profileOwnerId>`, mapped to the `Review` model.
- `addReview(...)` — inserts a review with `reviewer_id = auth.uid()` and the
  reviewer's name denormalized as `rater_name`.
- Providers: `profileRepositoryProvider` and `profileProvider` now resolve to
  the Supabase implementation; `LocalProfileRepository` stays in the repo only
  for offline widget tests.

## 7. NEW — Profile ratings

**`reviews` table:**

```sql
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  reviewee_id uuid not null references public.profiles (id) on delete cascade,
  reviewer_id uuid not null references auth.users (id) on delete cascade,
  rater_name text not null default '',
  rating smallint not null check (rating between 1 and 5),
  comment text not null default '',
  listing_title text,
  created_at timestamptz not null default now(),
  unique (reviewer_id, reviewee_id)
);
```

- RLS: `select` public; `insert` only for authenticated users with
  `reviewer_id = auth.uid()`; `update`/`delete` only the reviewer's own rows.
- Add to `supabase_realtime`; `replica identity full` (so DELETE events stream
  full rows to clients).
- Rating is 1–5 stars; `rating` / `review_count` are **derived on read** by the
  repository (no denormalized counters to keep consistent).
- `unique (reviewer_id, reviewee_id)` prevents duplicate reviews; a second
  review upserts/updates the existing one.

**UI:**

- Profile header keeps the 5-star row + `X (N reviews)`; values now come from
  Supabase in realtime.
- Reviews tab keeps the star-distribution bars + review cards (now from
  `reviews` table).
- **Leave a review** — "Add review" button opens a bottom sheet with a 5-star
  picker and optional comment. Submission calls `addReview(...)`; the sheet
  surfaces errors (e.g. already reviewed) and success. Realtime refresh makes
  the new rating appear immediately.

## 8. Schema & migrations

- `supabase/migrations/0001_initial.sql` — unchanged (listings,
  `listing_swipes`, RLS, realtime). Listings RLS stays keyed to `auth.uid()`;
  now backed by real accounts instead of anonymous sessions.
- **New** `supabase/migrations/0002_users_ratings.sql` — `profiles` table +
  `handle_new_user` trigger, `reviews` table, RLS policies, realtime
  publication, `replica identity full`.
- Apply via `supabase db push` or the project SQL editor.

## 9. App wiring changes

- `lib/main.dart` — keep `Supabase.initialize(url:, publishableKey:)`; **remove**
  `signInAnonymously()`. Keep opening the Drift DB for chat/messages.
- `lib/core/providers/app_providers.dart`:
  - Add `authGatewayProvider` (`AuthGateway` abstraction) and
    `authSessionProvider` (stream of current user id, null when signed out).
  - `currentUserIdProvider` reads the authenticated user (throws if absent).
  - `profileRepositoryProvider` → `SupabaseProfileRepository`.
- `lib/core/router/app_router.dart` — add `/login`, `/signup`, `/verify-email`
  routes outside the shell; add `redirect` + `refreshListenable` auth guard.
- New `lib/core/auth/` — `auth_gateway.dart` (interface + Supabase impl),
  `captcha.dart` (math-captcha challenge widget + verifier).
- New `lib/features/auth/` — `login_screen.dart`, `signup_screen.dart`,
  `verify_email_screen.dart`.
- `lib/features/profile/` — profile header + reviews now Supabase-driven; add
  "Leave a review" sheet; add Sign out entry.
- `test/widget_test.dart` — keep offline: override `authGatewayProvider` (fake,
  signed in), `listingRepositoryProvider` (Drift), `profileRepositoryProvider`
  (Drift); remove reliance on anonymous sign-in.

## 10. Non-goals / constraints

- **Chat, messages, and conversations remain on local Drift.** No chat sync.
- No payments, escrow, push notifications, or geolocation.
- Anonymous-user data migration is out of scope (see §4.8).
- Preserve performance-tier behavior (dynamic color only on high-end devices).
- No new runtime dependencies required by the captcha implementation; if an
  hCaptcha widget is added later it becomes an app dependency (optional).

## 11. Acceptance / verification

- `flutter analyze` — clean.
- `flutter test` — pass, offline (Supabase faked/overridden).
- Manual: sign up with captcha → confirmation email → open link → auto-login →
  sign out → sign back in → leave a review on a profile → rating + distribution
  update in realtime → verify unconfirmed-email path routes to `/verify-email`.
- `supabase db push` applies `0002_users_ratings.sql` without errors.