import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/routica_theme.dart';

/// A Dynamic Island-style congratulation banner that drops in from the top of
/// the screen, plays a celebratory particle "splash" and then retracts.
///
/// Designed to be inserted into the root [Overlay] so it floats above every
/// other surface (including the bottom navigation bar). It manages its own
/// entrance, hold and exit timing and invokes [onDismiss] once fully gone.
class AchievementIsland extends StatefulWidget {
  const AchievementIsland({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  final Achievement achievement;
  final VoidCallback onDismiss;

  @override
  State<AchievementIsland> createState() => _AchievementIslandState();
}

class _AchievementIslandState extends State<AchievementIsland>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _splash;
  late final List<_Particle> _particles;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 360),
    );
    _splash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particles = _buildParticles(widget.achievement.color);

    _enter.forward();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _splash.forward();
    });

    Future.delayed(const Duration(milliseconds: 3600), _dismiss);
  }

  List<_Particle> _buildParticles(Color base) {
    final random = math.Random(widget.achievement.id.hashCode);
    final palette = <Color>[
      base,
      RouticaTheme.accent,
      RouticaTheme.warning,
      Colors.white,
      const Color(0xFFF472B6),
    ];
    return List<_Particle>.generate(22, (i) {
      final angle = (i / 22) * math.pi * 2 + random.nextDouble() * 0.5;
      return _Particle(
        angle: angle,
        distance: 38 + random.nextDouble() * 54,
        size: 2.5 + random.nextDouble() * 4.5,
        color: palette[random.nextInt(palette.length)],
        delay: random.nextDouble() * 0.25,
      );
    });
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    if (mounted) {
      await _enter.reverse();
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _enter.dispose();
    _splash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final achievement = widget.achievement;

    final curved = CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Positioned(
      top: topInset + 8,
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _splash]),
            builder: (context, child) {
              final t = curved.value.clamp(0.0, 1.0);
              return Opacity(
                opacity: _enter.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -70 * (1 - _enter.value)),
                  child: Transform.scale(
                    scale: 0.82 + 0.18 * t,
                    child: child,
                  ),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _splash,
                      builder: (context, _) => CustomPaint(
                        painter: _SplashPainter(
                          progress: _splash.value,
                          particles: _particles,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildIsland(achievement),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIsland(Achievement achievement) {
    return GestureDetector(
      onTap: _dismiss,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: RouticaTheme.scaffoldBackground,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: achievement.color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: achievement.color.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      achievement.color,
                      achievement.color.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Icon(achievement.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Achievement Unlocked',
                          style: TextStyle(
                            color: achievement.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('🎉', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: RouticaTheme.warning,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double delay;
}

class _SplashPainter extends CustomPainter {
  _SplashPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final local = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeOut.transform(local);
      final pos = Offset(
        center.dx + math.cos(p.angle) * p.distance * eased,
        center.dy + math.sin(p.angle) * p.distance * eased,
      );
      final opacity = (1 - local).clamp(0.0, 1.0);
      final radius = p.size * (1 - 0.4 * local);

      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
