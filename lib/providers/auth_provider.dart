import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Singleton provider for the auth service.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Stream of the current Supabase auth state.
///
/// Emits a new [AuthState] whenever the user signs in, signs out,
/// or the token refreshes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Whether the current session has a signed-in user.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user != null,
    orElse: () => AuthService.instance.isAuthenticated,
  );
});

/// The current user, or null if not signed in.
final currentUserProvider = Provider<User?>((ref) {
  // Watch auth state so we rebuild on changes
  ref.watch(authStateProvider);
  return AuthService.instance.currentUser;
});

/// Whether the user chose to continue as a guest (no login).
///
/// Stored in Hive so it persists across app restarts.
final isGuestProvider = StateProvider<bool>((ref) {
  final box = Hive.box('app_settings');
  return box.get('is_guest', defaultValue: false) as bool;
});

/// Provider to toggle guest mode.
final guestModeProvider = NotifierProvider<GuestModeNotifier, bool>(
  GuestModeNotifier.new,
);

class GuestModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final box = Hive.box('app_settings');
    return box.get('is_guest', defaultValue: false) as bool;
  }

  /// Enable guest mode (continue without login).
  void enable() {
    state = true;
    Hive.box('app_settings').put('is_guest', true);
  }

  /// Disable guest mode (user signed in or wants to log in).
  void disable() {
    state = false;
    Hive.box('app_settings').put('is_guest', false);
  }
}

/// Whether onboarding has been completed.
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final box = Hive.box('app_settings');
  return box.get('onboarding_complete', defaultValue: false) as bool;
});

/// Provider to mark onboarding as complete.
final onboardingNotifier = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final box = Hive.box('app_settings');
    return box.get('onboarding_complete', defaultValue: false) as bool;
  }

  void markComplete() {
    state = true;
    Hive.box('app_settings').put('onboarding_complete', true);
  }
}
