import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/app.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/theme/widgets/gigl_logo.dart';

// Re-export for callers that reference the bootstrap symbol from main.dart.
export 'package:marketplace_gig/core/providers/app_providers.dart'
    show initializeFirebase;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set conservative defaults; will be tuned per device tier after bootstrap
  // to avoid allocating 50MB on 1GB RAM low-end devices.
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  // Non-blocking bootstrap: show branded splash instantly so Activity.onCreate
  // returns immediately on low-end devices. Heavy I/O (Firebase restore,
  // Drift open) runs after first frame, fixing ANR (~5s watchdog).
  runApp(const ProviderScope(child: StartupBootstrap()));
}

/// Observes the two async initializations that previously blocked `main()`.
///
/// While either is loading, the branded splash stays visible (mirrors the
/// native `LaunchTheme` color so there's no white flash). Errors are surfaced
/// with a retry that invalidates both providers.
class StartupBootstrap extends ConsumerWidget {
  const StartupBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    final fbAsync = ref.watch(firebaseInitProvider);

    final hasError = dbAsync.hasError || fbAsync.hasError;
    final isLoading = dbAsync.isLoading || fbAsync.isLoading;

    if (hasError) {
      final error = dbAsync.error ?? fbAsync.error;
      final stack = dbAsync.stackTrace ?? fbAsync.stackTrace;
      if (error != null) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
      return _BootstrapErrorScreen(
        details: error.toString(),
        onRetry: () {
          ref.invalidate(appDatabaseProvider);
          ref.invalidate(firebaseInitProvider);
        },
      );
    }

    if (isLoading) {
      return const BrandedSplash();
    }

    // Both ready: mount the real app. Device-tier tuning of the image cache
    // happens inside MarketplaceApp/AppBootstrap after the tier is known.
    return const AppBootstrap(child: MarketplaceApp());
  }
}

/// Branded splash shown while Drift/Firebase initialize after first frame.
/// Uses [AppColors.deepTeal] to match `android/app/src/main/res/values/colors.xml:splash_background`
/// so the native `LaunchTheme` and Flutter frame blend seamlessly.
class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.lightPrimary,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GiglLogo(size: 96),
                const SizedBox(height: 16),
                Text(
                  'Marketplace & Gig',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.lightOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tagum City',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.lightOnPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.lightOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.details, required this.onRetry});

  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Could not start the app',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Marketplace & Gig could not be initialized. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
                    ),
                    child: SelectableText(
                      details,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
