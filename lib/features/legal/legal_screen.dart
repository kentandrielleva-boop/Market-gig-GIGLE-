import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/app_header.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/features/legal/legal_consent_providers.dart';
import 'package:marketplace_gig/features/legal/legal_docs.dart';

/// Tappable inline links to the combined legal doc.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({
    super.key,
    this.prefix = 'By continuing you agree to our ',
  });

  final String prefix;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final linkStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: style?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: 'Terms & EULA',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal'),
          ),
          const TextSpan(text: ' (v$kLegalVersion).'),
        ],
      ),
    );
  }
}

/// Full-screen reader for the combined Terms & EULA.
///
/// When [gate] is true the screen is blocking: back navigation is disabled
/// and the user must Accept (or sign out / leave) to proceed.
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key, this.gate = false});

  final bool gate;

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(legalAcceptanceProvider.notifier).accept();
      if (!mounted) return;
      if (widget.gate) {
        // Gate entered from redirect: return to the app root and let the
        // guard re-evaluate (now accepted).
        context.go('/home');
      } else {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      body: AppBackdrop(
        variant: AppBackdropVariant.form,
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: kLegalTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version $kLegalVersion • $kLegalLastUpdated',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const SelectableText(kTermsEulaText),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkButton(
                      onPressed: _accept,
                      busy: _busy,
                      label: widget.gate ? 'Accept & Continue' : 'Accept',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.gate) return body;
    // Blocking gate: disable back button / swipe-to-pop.
    return PopScope(canPop: false, child: body);
  }
}

/// Non-dismissible dialog used for version-change re-prompts inside the app
/// (first-launch gate is handled by the router redirect to /legal?gate=true).
Future<void> showLegalGateDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text(kLegalTitle),
      content: const SizedBox(
        width: double.maxFinite,
        height: 320,
        child: SingleChildScrollView(child: Text(kTermsEulaText)),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            await ref.read(legalAcceptanceProvider.notifier).accept();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Accept & Continue'),
        ),
      ],
    ),
  );
}
