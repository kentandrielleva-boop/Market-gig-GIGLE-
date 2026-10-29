import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/features/auth/auth_screens.dart';
import 'package:marketplace_gig/features/discovery/models/feed_filter.dart';
import 'package:marketplace_gig/features/home/data/node_data.dart';
import 'package:marketplace_gig/features/home/home_screen.dart';
import 'package:marketplace_gig/features/home/providers/node_home_provider.dart';
import 'package:marketplace_gig/features/home/screens/node_home_screen.dart';
import 'package:marketplace_gig/features/home/screens/section_screens.dart';
import 'package:marketplace_gig/features/inbox/chat_thread_screen.dart';
import 'package:marketplace_gig/features/inbox/inbox_screen.dart';
import 'package:marketplace_gig/features/legal/legal_consent_providers.dart';
import 'package:marketplace_gig/features/legal/legal_screen.dart';
import 'package:marketplace_gig/features/listing/listing_detail_screen.dart';
import 'package:marketplace_gig/features/post/post_sheet.dart';
import 'package:marketplace_gig/features/profile/profile_edit_screen.dart';
import 'package:marketplace_gig/features/profile/profile_screen.dart';
import 'package:marketplace_gig/features/profile/user_profile_screen.dart';
import 'package:marketplace_gig/features/saved/saved_screen.dart';
import 'package:marketplace_gig/features/shell/image_cache_observer.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies go_router whenever the auth session, email verification, or legal
/// acceptance changes so its redirect can re-run (moving signed-out users to
/// /login, unverified users to /verify-email, verified users home, and
/// unaccepted users to the legal gate).
/// Listens to [authSessionProvider], [emailVerifiedProvider], and
/// [legalAcceptanceProvider] state changes so the redirect always observes
/// the providers' latest values.
class _AuthRefreshListenable extends ValueNotifier<int> {
  _AuthRefreshListenable(this._ref) : super(0) {
    _authSub = _ref.listen<AsyncValue<String?>>(
      authSessionProvider,
      (previous, next) => value++,
    );
    _verifiedSub = _ref.listen<AsyncValue<bool>>(
      emailVerifiedProvider,
      (previous, next) => value++,
    );
    _legalSub = _ref.listen<AsyncValue<bool>>(
      legalAcceptanceProvider,
      (previous, next) => value++,
    );
  }

  final Ref _ref;
  ProviderSubscription<AsyncValue<String?>>? _authSub;
  ProviderSubscription<AsyncValue<bool>>? _verifiedSub;
  ProviderSubscription<AsyncValue<bool>>? _legalSub;

  @override
  void dispose() {
    _authSub?.close();
    _verifiedSub?.close();
    _legalSub?.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshListenable(ref);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authRefresh,
    observers: [ImageCacheRouteObserver()],
    redirect: (context, state) {
      final userId = ref.read(authSessionProvider).value;
      final loggedIn = userId != null;
      final location = state.matchedLocation;
      final isAuthPath =
          location == '/login' ||
          location == '/signup' ||
          location == '/verify-email';
      final isLegalPath = location == '/legal';

      // Legal text is always readable (logged out, signing up, or gated).
      if (isLegalPath) return null;

      if (!loggedIn && !isAuthPath) return '/login';
      if (!loggedIn && location == '/verify-email') return '/login';

      // Firebase keeps a session for unverified users: hold them on
      // /verify-email until the flag flips. While the check is
      // loading/erroring, assume verified to avoid lockout flicker.
      if (loggedIn) {
        final verifiedAsync = ref.read(emailVerifiedProvider);
        final verified = !verifiedAsync.hasValue || verifiedAsync.value!;
        if (!verified && location != '/verify-email') {
          return '/verify-email';
        }
        if (verified && isAuthPath) return '/home';
      }

      // Blocking gate: signed-in users who have not accepted the current
      // Terms & EULA version are forced to /legal?gate=true. While the
      // acceptance check is loading/erroring we do NOT block, to avoid
      // lockout flicker on slow storage or offline backfill failures.
      if (loggedIn) {
        final legalAsync = ref.read(legalAcceptanceProvider);
        if (legalAsync.hasValue && legalAsync.value == false) {
          return '/legal?gate=true';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return VerifyEmailScreen(
              email: extra['email'] as String?,
              initialName: extra['name'] as String?,
            );
          }
          return VerifyEmailScreen(email: extra as String?);
        },
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) {
          final gate = state.uri.queryParameters['gate'] == 'true';
          return LegalScreen(gate: gate);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NodeHomeScreen()),
            routes: [
              GoRoute(
                path: 'discover/nearby',
                builder: (context, state) =>
                    const HomeScreen(filter: FeedFilter.nearby),
              ),
              GoRoute(
                path: 'discover/trending',
                builder: (context, state) =>
                    const HomeScreen(filter: FeedFilter.trending),
              ),
              GoRoute(
                path: 'discover/feed',
                builder: (context, state) =>
                    const HomeScreen(filter: FeedFilter.forYou),
              ),
              GoRoute(
                path: 'discover/filters',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const FilterSheetScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/inbox',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InboxScreen()),
            routes: [
              GoRoute(
                path: 'requests',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const RequestsScreen(),
              ),
              GoRoute(
                path: 'archived',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ArchivedChatsScreen(),
              ),
              GoRoute(
                path: ':conversationId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ChatThreadScreen(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/saved',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SavedScreen()),
            routes: [
              GoRoute(
                path: 'liked',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const LikedItemsScreen(),
              ),
              GoRoute(
                path: 'collections',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CollectionsScreen(),
              ),
              GoRoute(
                path: 'history',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ProfileEditScreen(),
              ),
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const RatingsScreen(),
              ),
              GoRoute(
                path: 'settings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'blocked',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const BlockedUsersScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'wallet',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/gigs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BrowseGigsScreen(),
      ),
      GoRoute(
        path: '/gigs/mine',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyGigsScreen(),
      ),
      GoRoute(
        path: '/gigs/reviews',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RatingsScreen(title: 'Gig reviews'),
      ),
      GoRoute(
        path: '/market',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AllItemsScreen(),
      ),
      GoRoute(
        path: '/market/mine',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/market/deals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DealsScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          return ListingDetailScreen(
            listingId: state.pathParameters['id']!,
            initialListing: extra is Listing ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/user/:uid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PublicProfileScreen(uid: state.pathParameters['uid']!),
      ),
    ],
  );
});

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    // The swipe feed has its own Post button in the action row; a floating
    // one would sit on top of the Save button.
    final showPostFab = !location.startsWith('/home/discover');

    // The radial menu is the only navigation, and leaves use context.go
    // (no history), so system back returns to it instead of exiting.
    // The floating dock overlays only its own tight bottom bounds, so hub
    // gestures anywhere above it are unaffected. On /home the dock doubles
    // as the focused-node readout (label + description); elsewhere it shows
    // the static brand lines. Watch-only: no logic or routing changes.
    final onHomeRoute = location == '/home';
    final focusedId = onHomeRoute
        ? ref.watch(nodeHomeProvider.select((s) => s.focusedId))
        : null;
    final focusedNode = focusedId == null ? null : nodeById[focusedId];
    return PopScope(
      canPop: onHomeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: Stack(
          children: [
            child,
            if (showPostFab)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingDock(
                  title: focusedNode?.label ?? 'Gigl',
                  subtitle: focusedNode?.description ?? 'Marketplace & Gig',
                  onPost: () => showPostSheet(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
