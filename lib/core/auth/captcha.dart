import 'dart:math';

import 'package:flutter/material.dart';

/// A single-use arithmetic challenge used as the human-verification gate.
///
/// The solved [token] is verified locally before the auth call; Firebase
/// Auth has no server-side captcha token, so the gate itself is the
/// anti-bot check.
class CaptchaChallenge {
  CaptchaChallenge._(this._a, this._b, this._expected, this._token);

  final int _a;
  final int _b;
  final int _expected;
  final String _token;

  int get left => _a;
  int get right => _b;

  /// Opaque proof that the challenge was solved by this client.
  String get token => _token;

  bool verify(int answer) => answer == _expected;
}

class MathCaptcha {
  static CaptchaChallenge createChallenge({Random? random}) {
    final rng = random ?? Random();
    final a = 1 + rng.nextInt(9);
    final b = 1 + rng.nextInt(9);
    final token =
        'math-$a+$b-${rng.nextInt(1 << 31)}-${DateTime.now().millisecondsSinceEpoch}';
    return CaptchaChallenge._(a, b, a + b, token);
  }
}

/// Renders the "what is a + b?" challenge and reports the solved token via
/// [onVerified]. Emits null again if the answer is edited after being correct.
class CaptchaField extends StatefulWidget {
  const CaptchaField({super.key, required this.onVerified});

  final ValueChanged<String?> onVerified;

  @override
  State<CaptchaField> createState() => _CaptchaFieldState();
}

class _CaptchaFieldState extends State<CaptchaField> {
  late CaptchaChallenge _challenge;
  late final TextEditingController _controller;
  String? _emittedToken;

  @override
  void initState() {
    super.initState();
    _challenge = MathCaptcha.createChallenge();
    _controller = TextEditingController()..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final parsed = int.tryParse(_controller.text.trim());
    final verified = parsed != null && _challenge.verify(parsed);
    final token = verified ? _challenge.token : null;
    if (token != _emittedToken) {
      _emittedToken = token;
      widget.onVerified(token);
    }
  }

  void _refresh() {
    setState(() {
      _challenge = MathCaptcha.createChallenge();
      _controller.clear();
      _emittedToken = null;
      widget.onVerified(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'What is ${_challenge.left} + ${_challenge.right}?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Answer',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              tooltip: 'New challenge',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
