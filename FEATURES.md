# Gigl — Feature Guide

**Marketplace & Gig** (app name: *Gigl*) is an Android app that combines a local
buy/sell marketplace with a gig-economy platform. People post items for sale or
jobs they need done, discover each other's posts, chat in realtime, and rate
each other afterwards. It runs on phones with Material Design 3 and works on
low-end devices.

---

## 1. Accounts & security

| Feature | What it does | How it's used |
|---|---|---|
| Sign-up | Create an account with email and password | Enter email, password, and a display name; a **math captcha** must be solved first to stop bots |
| Sign-in | Returning users sign in with email/password | Same math captcha applies; session persists so most users sign in once |
| Email verification | A verification link is emailed at sign-up | New users are held on a "Verify email" screen until they tap the link, then press **"I've verified"**; a **Resend** button re-sends the email |
| Terms & EULA gate | The app tracks which terms version each user accepted | When a new version ships, signed-in users must accept it before continuing; loading or offline states never lock the user out |
| Sign-out | Ends the session and wipes local offline data | From the Profile screen (confirmation dialog); cached chats and swipe history are cleared |

## 2. Home & navigation

The home screen is a **radial menu** — a hub-and-spoke layout instead of a
bottom navigation bar. The root node "Gigl" branches into six main sections,
each expanding into sub-items:

| Main section | Sub-items |
|---|---|
| **Discover** | Nearby, Trending, For you, Filters |
| **Gigs** | Browse, My gigs, Reviews |
| **Market** | All items, My listings, Deals |
| **Chats** | Active, Requests, Archived |
| **Saved** | Liked, Collections, History |
| **Profile** | Profile, Ratings, Settings, Wallet |

Tapping a leaf opens its screen; a breadcrumb shows where you are. A floating
**Post** button sits on every main screen. System back always returns home.

## 3. Discovering listings

- **Only other people's posts** — your own items and gigs never appear in
  discovery (feed, Browse, Deals); find them under My listings / My gigs.
- **Swipe feed** — Tinder-style card stack: swipe (or tap Pass/Save) through
  listings one at a time.
- **Three feed orderings** — *Nearby* (sorted by location), *Trending*
  (highest price first), *For you* (default order).
- **Filters** — a dedicated filter screen with:
  - Type: All / Items / Gigs
  - Category (General, Services, Electronics)
  - Price range (₱)
  - "Show results" applies and returns to the feed; Reset clears everything.
- **Passed history** — listings you swiped past are kept so you can restore
  them later.

## 4. Market (buy & sell items)

- **All items** — every listing of type *item* for sale.
- **My listings** — items you posted, with status badges
  (Active / Completed).
- **Deals** — all items sorted cheapest first.
- **Listing detail** — photos, price, description, category, location,
  remote-only flag, and the seller's profile card (tap to open their public
  profile). Actions: **Pass**, **Save** (adds to likes), open the seller
  profile.

## 5. Gigs (services)

- **Browse gigs** — every listing of type *gig* (jobs/services offered or
  wanted).
- **My gigs** — gigs you posted, with status.
- **Gig reviews** — the reviews you've received, shown as a star distribution.

## 6. Posting

A modal bottom sheet launched by the floating **Post** button:

- **Type toggle** — Item (sell) or Gig (service).
- **Fields** — Title, Price / Budget, Location, Description.
- **Gig extras** — duration and remote-only options for gigs.
- **Photos** — multi-photo grid upload (goes to Cloudinary); required photos
  are validated before submission.
- **Edit & delete** — owners can edit a listing (including marking it
  **Completed**) or delete it from the listing's menu.

## 7. Chat & inbox

- **Start a chat** — "Message seller" (or "Message poster" for gigs) on any
  listing you don't own opens a thread with its owner. Tapping it again
  reopens the same thread rather than starting a new one.
- **Conversation list** — searchable inbox with the other party's name, the
  listing being discussed, last message, timestamp, and unread badge.
- **Thread view** — realtime 1-to-1 messaging, **20 messages per page**
  (scroll up for older); typing indicator supported.
- **Requests** — conversations with unread messages, for triage.
- **Offline** — chat history is cached locally on the phone, so past
  conversations read instantly without a connection; sending while offline
  keeps the message locally and syncs when possible.
- **Notifications** — push notifications for new messages; tapping one opens
  that conversation directly.
- Threads open from the Inbox or a tapped notification (see limitations for
  starting a new one).

## 8. Saved

- **Liked** — everything you swiped/saved; one tap to remove.
- **Collections** — liked items grouped by category.
- **History** — listings you passed, with one-tap **Restore**.

## 9. Profiles & ratings

- **My profile** — name, bio, avatar (photo upload), plus lists of my
  listings and reviews.
- **Edit profile** — change name, bio, avatar.
- **Public profile** — reachable from any listing's seller card; shows the
  user's info, rating average, review count, and their reviews (read-only —
  the "Leave a review" button is hidden there).
- **Ratings & reviews** — a **"Rate this user"** sheet (1–5 stars + optional
  comment) opens from the Reviews tab via **"Leave a review"** (present on
  the profile and Ratings screens in the current build). One review per
  reviewer — resubmitting updates your existing review; the profile's
  average and count are recomputed in a single transaction, so aggregates
  update immediately. A star-distribution chart shows the breakdown.
- **Settings** — account email, edit profile, Terms & EULA. Sign-out lives on
  the Profile screen (confirmation dialog).

## 10. Wallet

A personal earnings dashboard (no real payments — informational):

- **Total earned** — sum of prices of your completed listings.
- **Active / Completed** counters.
- **Earnings list** — each completed listing, tap to open.

## 11. Safety & moderation

- **Report a listing** — reason (enum) + free-text details, submitted from
  the listing's menu. Reports are create-only and reviewed in the Firebase
  console (no in-app moderation UI yet).
- **Math captcha** on sign-up/sign-in as basic anti-bot protection.

## 12. Performance tiers

The app detects device capability and switches modes:

- **High-end** — dynamic color, card peek, gradient overlays, larger image
  cache.
- **Low-end** — simplified visuals for smooth scrolling.

Branded splash screen while the local database and Firebase initialize,
designed to avoid freezes (ANRs) on cheap phones.

---

## What powers it

| Concern | Technology |
|---|---|
| Accounts / login | Firebase Authentication (email + password) |
| Listings, profiles, reviews, chat data | Cloud Firestore (free Spark plan) |
| Photos | Cloudinary (unsigned upload preset) |
| Offline chat & history cache | SQLite via Drift, on-device |
| Navigation, UI | go_router, Material Design 3, Riverpod |

## Who uses what

| Action | Buyer / browser | Seller / gig poster |
|---|---|---|
| Browse & filter listings | ✅ | ✅ |
| Swipe feed, save, pass | ✅ | ✅ |
| Post item or gig with photos | ✅ | ✅ |
| Edit / mark completed / delete own listing | — | ✅ |
| Chat with the other party | ✅ ("Message seller" on a listing, or Inbox) | ✅ (from Inbox) |
| Leave a 1–5 star review | ✅ | ✅ |
| Report a listing | ✅ | ✅ |
| View earnings dashboard | — | ✅ |

## Not included (current scope)

- **No in-app payments** — Wallet is informational; transactions happen
  offline between parties.
- **No in-app moderation console** — reports are reviewed in the Firebase
  backend console.
- **No archived chats yet** — the Archived screen is a placeholder.
- **Android only** — no iOS/web build configured.
- **No seeded demo data** — a fresh install starts empty.

> Note: files in `docs/` describe an older version of the app that used a
> different backend. This guide and `README.md` reflect the current app.
