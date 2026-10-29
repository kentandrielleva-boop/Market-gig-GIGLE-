import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/auth/captcha.dart';

/// Human-verification gate: offline math challenge.
///
/// Firebase Auth has no server-side captcha token, so the solved math token
/// solved math token is the anti-bot check itself — it is verified locally
/// before the auth call and ignored by the gateway. Same [onVerified]
/// contract as before, so auth screens don't branch. [reset] forces a fresh
/// challenge and clears the token.
class CaptchaGate extends StatefulWidget {
  const CaptchaGate({super.key, required this.onVerified});

  final ValueChanged<String?> onVerified;

  @override
  State<CaptchaGate> createState() => CaptchaGateState();
}

class CaptchaGateState extends State<CaptchaGate> {
  int _generation = 0;

  /// Clears any solved token and renders a fresh challenge.
  void reset() {
    widget.onVerified(null);
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    return CaptchaField(
      key: ValueKey('math-$_generation'),
      onVerified: widget.onVerified,
    );
  }
}
