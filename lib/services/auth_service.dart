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
  /// Returns null on success, or an error message string on failure.
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
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// Sign in with email and password.
  ///
  /// Returns null on success, or an error message string on failure.
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
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// Send a password reset email.
  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────

  /// Sign in with Google.
  ///
  /// Uses the `google_sign_in` package to obtain an ID token,
  /// then verifies it with Supabase.
  ///
  /// Returns null on success, or an error message on failure.
  Future<String?> signInWithGoogle() async {
    // Check if Google Sign-In has been configured.
    if (_googleServerClientId.isEmpty) {
      return 'Google Sign-In is not configured. Set the GOOGLE_WEB_CLIENT_ID '
          'environment variable.';
    }
    try {
      // Configure Google Sign-In with server client ID for Supabase.
      // The webClientId is the OAuth 2.0 Web Application client ID
      // from Google Cloud Console (needed for ID token).
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
        return 'Failed to get Google ID token';
      }

      // Sign in to Supabase with the Google ID token
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      // Sign out of Google if signed in
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
      return 'Failed to update name: $e';
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
