import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';
import 'package:marketplace_gig/core/notifications/push_service.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/router/app_router.dart';
import 'package:marketplace_gig/core/theme/app_theme.dart';
import 'package:marketplace_gig/core/theme/theme_mode_provider.dart';

class MarketplaceApp extends ConsumerStatefulWidget {
  const MarketplaceApp({super.key});

  @override
  ConsumerState<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends ConsumerState<MarketplaceApp> {
  @override
  void initState() {
    super.initState();
    pushConversationTap.addListener(_onPushTap);
  }

  void _onPushTap() {
    final convId = pushConversationTap.value;
    if (convId == null) return;
    pushConversationTap.value = null;
    ref.read(appRouterProvider).push('/inbox/$convId');
  }

  @override
  void dispose() {
    pushConversationTap.removeListener(_onPushTap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    ref.watch(pushInitProvider);
    final tierAsync = ref.watch(deviceTierProvider);
    final tier = tierAsync.value ?? DeviceTier.low;
    final themeMode = ref.watch(themeModeProvider);

    // Tune image cache once tier is known; low-end gets smaller cache to
    // reduce RAM pressure and GC pauses seen in logs (`Background concurrent
    // mark compact GC freed 2480KB`).
    ref.listen<AsyncValue<DeviceTier>>(deviceTierProvider, (prev, next) {
      final resolved = next.value ?? DeviceTier.low;
      final cache = PaintingBinding.instance.imageCache;
      if (resolved == DeviceTier.low) {
        cache.maximumSize = 60;
        cache.maximumSizeBytes = 20 << 20; // 20MB vs 50MB default
      } else {
        cache.maximumSize = 100;
        cache.maximumSizeBytes = 50 << 20;
      }
    });

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Keep the explicit Gigl palettes when dynamicScheme is null or tier
        // is low, per user choice. Only high tier gets the system
        // dynamic_color palettes — and each ThemeData gets the palette whose
        // brightness matches it (mixing them trips the
        // ThemeData/ColorScheme brightness assertion and red-screens).
        final lightDynamicScheme = tier == DeviceTier.high
            ? lightDynamic
            : null;
        final darkDynamicScheme = tier == DeviceTier.high ? darkDynamic : null;

        // AmbientClock owns the ONE ambient ticker (mesh/patches/rings
        // repaint from it; no widget rebuilds). Above MaterialApp so every
        // route shares the same clock; painters fall back to a static t=0
        // frame when reduced-motion / covered route / motion-off applies.
        return AmbientClock(
          child: MaterialApp.router(
            title: 'Marketplace & Gig',
            debugShowCheckedModeBanner: false,
            theme: buildGiglTheme(
              brightness: Brightness.light,
              tier: tier,
              dynamicScheme: lightDynamicScheme,
            ),
            darkTheme: buildGiglTheme(
              brightness: Brightness.dark,
              tier: tier,
              dynamicScheme: darkDynamicScheme,
            ),
            themeMode: themeMode,
            routerConfig: router,
          ),
        );
      },
    );
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly warm device tier detection without blocking splash; the
    // MarketplaceApp listener will tune cache once resolved.
    ref.watch(deviceTierProvider);
    return child;
  }
}
