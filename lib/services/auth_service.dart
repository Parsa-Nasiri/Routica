import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service wrapping Supabase auth.
///
/// Supports:
///   • Email + password sign-up / sign-in
///   • Google sign-in (via ID token)
///   • Password reset
///   • Guest mode (continue without login — local-only)
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current session, or null if not signed in.
  Session? get currentSession => _client.auth.currentSession;

  /// Current user, or null if not signed in.
  User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => currentUser != null;

  // ── Email / Password ──────────────────────────────────────────

  /// Sign up with email and password.
  ///
  /// Returns null on success, or a user-friendly error message string on failure.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        },
      );

      if (response.user == null) {
        return 'Sign-up failed. Please try again.';
      }

      // Check if email confirmation is required
      if (response.session == null) {
        return null; // Email confirmation pending — handled by caller
      }

      return null; // success
    } on AuthException catch (e) {
      // Map common Supabase error messages to user-friendly text
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already been registered')) {
        return 'An account with this email already exists. Try signing in instead.';
      }
      if (msg.contains('password') && msg.contains('weak')) {
        return 'Password is too weak. Use at least 6 characters.';
      }
      if (msg.contains('email') && msg.contains('invalid')) {
        return 'Please enter a valid email address.';
      }
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return e.message;
    } catch (e) {
      if (kDebugMode) debugPrint('signUpWithEmail error: $e');
      return 'Could not complete sign-up. Check your connection and try again.';
    }
  }

  /// Sign in with email and password.
  ///
  /// Returns null on success, or a user-friendly error message string on failure.
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid credentials') || msg.contains('wrong password')) {
        return 'Incorrect email or password.';
      }
      if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
        return 'Please verify your email before signing in. Check your inbox.';
      }
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return e.message;
    } catch (e) {
      if (kDebugMode) debugPrint('signInWithEmail error: $e');
      return 'Could not sign in. Check your connection and try again.';
    }
  }

  /// Send a password reset email.
  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Too many requests. Please wait before trying again.';
      }
      return e.message;
    } catch (e) {
      if (kDebugMode) debugPrint('resetPassword error: $e');
      return 'Could not send reset email. Check your connection and try again.';
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────

  /// Sign in with Google.
  ///
  /// Uses the `google_sign_in` package to obtain an ID token,
  /// then verifies it with Supabase.
  ///
  /// Returns null on success, or a user-friendly error message on failure.
  Future<String?> signInWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      return 'Google Sign-In is not configured. The app needs a '
          'GOOGLE_WEB_CLIENT_ID to be set at build time.';
    }

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        serverClientId: _googleServerClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return 'Sign-in cancelled';
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return 'Failed to get Google ID token. Make sure the SHA-1 '
            'fingerprint of your signing key is registered in '
            'Google Cloud Console.';
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      return null; // success
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not approved') || msg.contains('provider')) {
        return 'Google provider not enabled in Supabase. Enable it in '
            'Dashboard → Authentication → Providers → Google.';
      }
      return e.message;
    } on PlatformException catch (e) {
      // The common sign_in_failed PlatformException
      final code = e.code;
      if (kDebugMode) {
        debugPrint('GoogleSignIn PlatformException: code=$code, '
            'message=${e.message}, details=${e.details}');
      }
      switch (code) {
        case 'sign_in_failed':
          return 'Google Sign-In failed. This usually means the app\'s '
              'SHA-1 fingerprint is not registered in Google Cloud Console, '
              'or the OAuth client ID doesn\'t match. If this is a release '
              'build, make sure the release SHA-1 is added.';
        case 'network_error':
          return 'Network error. Check your connection and try again.';
        case 'sign_in_canceled':
          return 'Sign-in cancelled.';
        default:
          return 'Google Sign-In failed ($code). Please try again.';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('signInWithGoogle error: $e');
      // Detect PlatformException even if not caught by the type
      final str = e.toString();
      if (str.contains('sign_in_failed')) {
        return 'Google Sign-In failed. The app\'s SHA-1 fingerprint may not '
            'be registered in Google Cloud Console.';
      }
      return 'Google sign-in failed. Please try again.';
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore Google sign-out errors
    }

    await _client.auth.signOut();
  }

  /// Update the user's full name in Supabase.
  Future<String?> updateFullName(String fullName) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      if (kDebugMode) debugPrint('updateFullName error: $e');
      return 'Failed to update name. Please try again.';
    }
  }

  /// The Google OAuth 2.0 Web Application client ID.
  ///
  /// Passed at build time via `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
  /// In GitHub Actions, set this as a repository secret named
  /// `GOOGLE_WEB_CLIENT_ID`.
  ///
  /// To run locally:
  ///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your_id.apps.googleusercontent.com
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  /// Whether Google Sign-In is configured.
  bool get isGoogleSignInConfigured => _googleServerClientId.isNotEmpty;
}
