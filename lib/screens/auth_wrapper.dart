import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'routica_home_screen.dart';

/// Decides which screen to show based on auth state.
///
/// Priority:
///   1. Onboarding not completed → [OnboardingScreen]
///   2. Not authenticated and not guest → [LoginScreen]
///   3. Authenticated or guest → [RouticaHomeScreen]
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingNotifier);
    final isGuest = ref.watch(guestModeProvider);
    final authState = ref.watch(authStateProvider);

    // Not through onboarding yet
    if (!onboardingComplete) {
      return OnboardingScreen(
        onComplete: () {
          ref.read(onboardingNotifier.notifier).markComplete();
        },
      );
    }

    // Check auth state
    final isAuthenticated = authState.maybeWhen(
      data: (state) => state.session?.user != null,
      orElse: () => AuthService.instance.isAuthenticated,
    );

    // Guest mode or authenticated → home
    if (isGuest || isAuthenticated) {
      return const RouticaHomeScreen();
    }

    // Not authenticated → login
    return const LoginScreen();
  }
}
