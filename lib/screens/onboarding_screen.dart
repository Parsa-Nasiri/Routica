import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/routica_theme.dart';

/// Professional 3-slide onboarding flow.
///
/// Shown only on first launch (controlled by [onboardingCompleteProvider]).
/// Each slide has a gradient hero illustration, title, and description.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentPage = 0;

  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      duration: RouticaTheme.animMedium,
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animController.reset();
    _animController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: RouticaTheme.animMedium,
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RouticaTheme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: RouticaTheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  _OnboardingPage(
                    icon: Icons.track_changes_rounded,
                    title: 'Build Better Habits',
                    description:
                        'Create and track daily habits with ease. '
                        'Set goals, get reminders, and watch your '
                        'routine come to life.',
                    gradientColors: [RouticaTheme.secondary, RouticaTheme.primary],
                  ),
                  _OnboardingPage(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Stay on Streak',
                    description:
                        'Never break the chain. Visualize your '
                        'progress with beautiful heatmaps and streak '
                        'counters that keep you motivated.',
                    gradientColors: [RouticaTheme.warning, RouticaTheme.danger],
                  ),
                  _OnboardingPage(
                    icon: Icons.emoji_events_rounded,
                    title: 'Achieve Your Goals',
                    description:
                        'Unlock achievements, track analytics, and '
                        'celebrate milestones. Your journey to a '
                        'better self starts here.',
                    gradientColors: [RouticaTheme.accent, RouticaTheme.secondary],
                  ),
                ],
              ),
            ),
            // Page indicators + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: RouticaTheme.animFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? RouticaTheme.accent
                              : RouticaTheme.borderStrong,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [RouticaTheme.secondary, RouticaTheme.primary],
                        ),
                        borderRadius:
                            BorderRadius.circular(RouticaTheme.radiusButton),
                        boxShadow: [
                          BoxShadow(
                            color: RouticaTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius:
                              BorderRadius.circular(RouticaTheme.radiusButton),
                          child: Center(
                            child: Text(
                              _currentPage == _pageCount - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page with gradient hero, title, and description.
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient hero illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 96,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: RouticaTheme.animMedium)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: RouticaTheme.animMedium,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 48),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RouticaTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: RouticaTheme.animSlow, delay: 100.ms)
              .slideY(begin: 0.3, end: 0, duration: RouticaTheme.animSlow),
          const SizedBox(height: 16),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 16,
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(duration: RouticaTheme.animSlow, delay: 200.ms)
              .slideY(begin: 0.3, end: 0, duration: RouticaTheme.animSlow),
        ],
      ),
    );
  }
}
