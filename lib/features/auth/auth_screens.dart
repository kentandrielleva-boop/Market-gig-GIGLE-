import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/auth/captcha_gate.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/features/legal/legal_consent_providers.dart';
import 'package:marketplace_gig/features/legal/legal_screen.dart';

/// Shared visual shell for the login/sign-up/verify screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        variant: AppBackdropVariant.form,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkButton(
      onPressed: (enabled && !loading) ? onPressed : null,
      busy: loading,
      label: label,
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaKey = GlobalKey<CaptchaGateState>();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _captchaToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty || _captchaToken == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authGatewayProvider)
          .signInWithPassword(
            email: email,
            password: password,
            captchaToken: _captchaToken,
          );
      // Signed in; the router guard moves to /verify-email (unverified) or
      // /home (verified) automatically.
    } on Object catch (error) {
      setState(() => _error = friendlyAuthMessage(error));
      _captchaKey.currentState?.reset();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to browse, sell, and gig.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CaptchaGate(
            key: _captchaKey,
            onVerified: (token) => setState(() => _captchaToken = token),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          _SubmitButton(
            label: 'Sign in',
            loading: _busy,
            enabled:
                _emailController.text.trim().isNotEmpty &&
                _passwordController.text.isNotEmpty &&
                _captchaToken != null,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/signup'),
            child: const Text("Don't have an account? Sign up"),
          ),
          const SizedBox(height: 8),
          const LegalLinksRow(),
        ],
      ),
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _captchaKey = GlobalKey<CaptchaGateState>();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _captchaToken;
  String? _pickedAvatarPath;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty &&
      _captchaToken != null &&
      _acceptedTerms &&
      !_busy;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _pickedAvatarPath = file.path);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final trimmedName = _nameController.text.trim();
    final password = _passwordController.text;
    if (trimmedName.isEmpty) {
      setState(() => _error = 'Display name is required.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters long.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _error = 'Please accept the Terms & EULA to create an account.',
      );
      return;
    }
    if (!_canSubmit) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final needsVerification = await ref
          .read(authGatewayProvider)
          .signUp(
            email: email,
            password: password,
            name: trimmedName,
            captchaToken: _captchaToken,
          );
      // Firebase signs the user in immediately, so the avatar can be
      // uploaded now even while the email is still unverified.
      if (_pickedAvatarPath != null) {
        try {
          final avatarUrl = await ref
              .read(profileRepositoryProvider)
              .uploadAvatar(_pickedAvatarPath!);
          await ref
              .read(profileRepositoryProvider)
              .updateProfile(name: trimmedName, bio: '', avatarUrl: avatarUrl);
        } catch (_) {
          // Avatar is optional enrichment — retry later via edit profile.
        }
      }
      // Stamp local acceptance now; the server row is stamped again
      // post-verification via the /legal gate.
      try {
        await ref.read(legalAcceptanceProvider.notifier).accept();
      } catch (_) {
        // Non-blocking: gate will re-prompt if this failed.
      }
      if (!mounted) return;
      if (needsVerification) {
        context.go(
          '/verify-email',
          extra: {'email': email, 'name': trimmedName},
        );
      }
      // Otherwise the router guard moves to /home automatically.
    } on Object catch (error) {
      setState(() => _error = friendlyAuthMessage(error));
      _captchaKey.currentState?.reset();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Join Marketplace & Gig to sell and find gigs.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _busy ? null : _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: _pickedAvatarPath != null
                        ? FileImage(File(_pickedAvatarPath!))
                        : null,
                    child: _pickedAvatarPath == null
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.photo_camera,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to add avatar (optional)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Display name *',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password (min 8 chars)',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          CaptchaGate(
            key: _captchaKey,
            onVerified: (token) => setState(() => _captchaToken = token),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _acceptedTerms = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: _busy
                        ? null
                        : () =>
                              setState(() => _acceptedTerms = !_acceptedTerms),
                    child: const LegalLinksRow(
                      prefix: 'I have read and agree to the ',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          _SubmitButton(
            label: 'Sign up',
            loading: _busy,
            enabled: _canSubmit,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email, this.initialName});

  /// Email shown to the user; falls back to the signed-in account's email.
  final String? email;
  final String? initialName;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _busy = false;
  bool _checking = false;
  String? _message;
  String? _error;

  Future<void> _resend() async {
    final email =
        widget.email ?? ref.read(authGatewayProvider).currentEmail ?? '';
    if (email.isEmpty) {
      setState(() => _error = 'No email address to resend to.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authGatewayProvider).resendConfirmation(email);
      setState(() => _message = 'Confirmation email sent. Check your inbox.');
    } on Object catch (error) {
      setState(() => _error = friendlyAuthMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final verified = await ref
          .read(authGatewayProvider)
          .refreshEmailVerified();
      if (!verified && mounted) {
        setState(
          () => _error = 'Not verified yet — tap the link in your email.',
        );
      }
      // When verified, emailVerifiedProvider flips and the router guard
      // moves to /home automatically.
    } on Object catch (error) {
      if (mounted) setState(() => _error = friendlyAuthMessage(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _useDifferentAccount() async {
    await ref.read(authGatewayProvider).signOut();
    if (mounted) context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? ref.watch(authGatewayProvider).currentEmail;
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'One more step to keep bots out.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            email == null || email.isEmpty
                ? 'We sent a confirmation link to your email.'
                : 'We sent a confirmation link to\n$email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the link in the email, then press the button below.',
            textAlign: TextAlign.center,
          ),
          if (widget.initialName != null &&
              widget.initialName!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Display name: ${widget.initialName}')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_message != null) ...[
            Text(_message!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          _SubmitButton(
            label: "I've verified my email",
            loading: _checking,
            enabled: true,
            onPressed: _checkVerified,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _resend,
            child: Text(_busy ? 'Sending…' : 'Resend email'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _useDifferentAccount,
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
