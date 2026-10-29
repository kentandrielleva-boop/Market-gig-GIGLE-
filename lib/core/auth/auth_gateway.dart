import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin abstraction over Firebase Auth so screens and tests don't reach into
/// the concrete client. The router guard and profile providers rely on
/// [userIdChanges] / [currentUserId] to learn who is signed in.
///
/// Unlike confirmation flows that block sign-in, Firebase keeps a session for
/// unverified users, so the router guard allows `/verify-email` while signed
/// with [isEmailVerified] false (see `app_router.dart`).
abstract class AuthGateway {
  /// Stream of the signed-in user id; emits null on sign-in/out.
  Stream<String?> get userIdChanges;

  /// Email-verification flag; emits on user changes (sign-in/out, reload).
  /// Firebase's `authStateChanges` skips profile refreshes, so this uses
  /// `userChanges` to let the router leave `/verify-email` without a restart.
  Stream<bool> get emailVerifiedChanges;

  /// The id of the currently signed-in user, or null.
  String? get currentUserId;

  /// Email of the currently signed-in user, or null.
  String? get currentEmail;

  /// Whether the current user completed email verification.
  bool get isEmailVerified;

  /// Creates an account, sends the verification email, and provisions the
  /// `profiles` doc. Returns true when the user must verify email first.
  /// [captchaToken] is the locally-solved math-captcha proof; Firebase has
  /// no server captcha, so it is accepted and ignored — the gate itself is
  /// the anti-bot check.
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? captchaToken,
  });

  Future<void> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  });

  /// Resends the verification email to the signed-in user.
  Future<void> resendConfirmation(String email, {String? captchaToken});

  /// Reloads the user and returns the fresh verification flag.
  Future<bool> refreshEmailVerified();

  Future<void> signOut();
}

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Stream<String?> get userIdChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Stream<bool> get emailVerifiedChanges =>
      _auth.userChanges().map((user) => user?.emailVerified ?? false);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? captchaToken,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final displayName = (name ?? '').trim();
    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    await user.sendEmailVerification();
    await _db.collection('profiles').doc(user.uid).set({
      'name': displayName.isEmpty ? 'User' : displayName,
      'bio': '',
      'avatar_url': '',
      'rating_sum': 0,
      'rating_count': 0,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.reload();
    return !(_auth.currentUser?.emailVerified ?? false);
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.reload();
  }

  @override
  Future<void> resendConfirmation(String email, {String? captchaToken}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Please sign in with $email first, then resend the verification email.',
      );
    }
    await user.sendEmailVerification();
  }

  @override
  Future<bool> refreshEmailVerified() async {
    await _auth.currentUser?.reload();
    return isEmailVerified;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Maps an auth failure to a concise, user-facing message.
bool isSignedOutError(Object error) =>
    error is StateError && error.message.contains('not signed in');

String friendlyAuthMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password must be at least 8 characters long.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
    }
    final message = error.message;
    if (message != null && message.isNotEmpty) return message;
    return 'Something went wrong.';
  }
  if (error is StateError && error.message.isNotEmpty) return error.message;
  return 'Something went wrong. Please try again.';
}
