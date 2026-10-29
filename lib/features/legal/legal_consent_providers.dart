import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/features/legal/legal_docs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local pref key prefix. Suffixed per user id (or `guest` when signed out)
/// so acceptance survives sign-out per device but is attributable per user.
String legalAcceptedKey(String? userId) =>
    'legal_accepted_v1_${userId ?? 'guest'}';

String legalVersionKey(String? userId) =>
    'legal_version_accepted_${userId ?? 'guest'}';

/// Whether the current user/device has accepted [kLegalVersion].
///
/// Source of truth is local SharedPreferences (offline-first). The Firestore
/// `profiles` doc (`terms_accepted_at` / `terms_version`) is the server audit
/// trail, stamped on accept and used to backfill local state when missing
/// (e.g. reinstall with same account).
final legalAcceptanceProvider =
    AsyncNotifierProvider<LegalAcceptanceNotifier, bool>(
      LegalAcceptanceNotifier.new,
    );

class LegalAcceptanceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Re-evaluate when auth changes (sign-in/out switches the per-user key).
    // Capture everything synchronously BEFORE any await: using ref after an
    // async gap inside build() throws ("Cannot use ref functions after the
    // dependency changed").
    final userId = ref.watch(authGatewayProvider).currentUserId;
    // Also watch session stream so sign-in/out rebuilds even if gateway
    // object identity is stable.
    ref.watch(authSessionProvider);
    final repo = ref.watch(profileRepositoryProvider);
    return hasAccepted(userId: userId, repo: repo);
  }

  /// Local check, optionally backfilled from Firestore when signed in.
  /// [repo] is passed in (rather than ref.read) so [build] stays
  /// sync-safe across async gaps.
  Future<bool> hasAccepted({String? userId, ProfileRepository? repo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getString(legalVersionKey(userId));
      if (storedVersion == kLegalVersion &&
          prefs.getBool(legalAcceptedKey(userId)) == true) {
        return true;
      }
    } catch (e) {
      debugPrint('legal local read failed: $e');
    }
    // Backfill: signed-in users whose server row already stamps this version
    // (e.g. accepted on another device) are treated as accepted locally too.
    if (userId != null && repo != null) {
      try {
        final remote = await repo.fetchLegalAcceptance();
        if (remote != null &&
            remote.version == kLegalVersion &&
            remote.acceptedAt != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(legalAcceptedKey(userId), true);
            await prefs.setString(legalVersionKey(userId), kLegalVersion);
          } catch (e) {
            debugPrint('legal backfill cache failed: $e');
          }
          return true;
        }
      } catch (e) {
        debugPrint('legal backfill failed: $e');
      }
    }
    return false;
  }

  /// Records acceptance locally and (best-effort) on the server row.
  Future<void> accept() async {
    final userId = ref.read(authGatewayProvider).currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(legalAcceptedKey(userId), true);
      await prefs.setString(legalVersionKey(userId), kLegalVersion);
    } catch (e) {
      debugPrint('legal local write failed: $e');
    }
    state = const AsyncData(true);
    if (userId != null) {
      try {
        await ref
            .read(profileRepositoryProvider)
            .recordLegalAcceptance(kLegalVersion);
      } catch (e) {
        // Local acceptance already grants access; server stamp retries on
        // next accept/backfill. Never block the user on a network error.
        debugPrint('recordLegalAcceptance failed: $e');
      }
    }
  }
}
