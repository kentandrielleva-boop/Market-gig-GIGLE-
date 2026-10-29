import 'package:flutter/material.dart';

/// Avoids aggressive clearing on low-end devices where GC was causing jank
/// (`GC freed 2480KB` on every home->chat navigation). Only evicts on
/// memory pressure now; navigation no longer mass-clears live images.
class ImageCacheRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // No-op: previously cleared cache on every push from home/chat which
    // triggered a full GC and re-decode jank (>30 skipped frames). Let the
    // normal LRU + tier-tuned maxSize handle eviction.
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // No-op for same reason.
  }
}
