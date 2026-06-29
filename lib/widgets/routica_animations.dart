import 'package:flutter/material.dart';

import '../theme/routica_theme.dart';

/// A widget that fades + slides its child in with a stagger delay.
///
/// Wrap list items in this to get a cascading entrance animation:
/// ```dart
/// StaggerFadeIn(index: 0, child: card1),
/// StaggerFadeIn(index: 1, child: card2),
/// ```
class StaggerFadeIn extends StatefulWidget {
  const StaggerFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 24,
    this.duration = RouticaTheme.animMedium,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<StaggerFadeIn> createState() => _StaggerFadeInState();
}

class _StaggerFadeInState extends State<StaggerFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final staggerDelay = Duration(
      milliseconds: widget.index * RouticaTheme.animStagger.inMilliseconds,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          staggerDelay.inMilliseconds /
              widget.duration.inMilliseconds.clamp(1, double.maxFinite.toInt()),
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          staggerDelay.inMilliseconds /
              widget.duration.inMilliseconds.clamp(1, double.maxFinite.toInt()),
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Start after the first frame so the initial state is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Animates a number from 0 to [target] on first build.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.target,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final num target;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _anim = Tween<double>(begin: 0, end: widget.target.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final value = _anim.value;
        final displayValue =
            value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(0);
        return Text(
          '${widget.prefix}$displayValue${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// An animated circular progress ring that fills from 0 to [percent].
class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    super.key,
    required this.percent,
    required this.gradient,
    this.size = 140,
    this.strokeWidth = 12,
    this.child,
  });

  final double percent; // 0.0 – 1.0
  final Gradient gradient;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RouticaTheme.animSlow,
    );
    _progress = Tween<double>(begin: 0, end: widget.percent).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RingPainter(
            progress: _progress.value,
            gradient: widget.gradient,
            strokeWidth: widget.strokeWidth,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.gradient,
    required this.strokeWidth,
  });

  final double progress;
  final Gradient gradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background ring)
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final sweepAngle = progress * 2 * pi;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

/// A single animated bar for bar-chart usage.  Grows from 0 to [height]
/// after first build, with an optional [delay] in milliseconds.
class AnimatedBar extends StatefulWidget {
  const AnimatedBar({
    super.key,
    required this.targetHeight,
    required this.color,
    this.maxHeight = 80,
    this.width = 18,
    this.delay = 0,
  });

  final double targetHeight;
  final Color color;
  final double maxHeight;
  final double width;
  final int delay;

  @override
  State<AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<AnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RouticaTheme.animMedium,
    );
    _anim = Tween<double>(begin: 0, end: widget.targetHeight).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: _anim.value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                widget.color.withOpacity(0.6),
                widget.color,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.width / 2),
          ),
        );
      },
    );
  }
}

/// Wraps a child and animates it when [shouldAnimate] changes.
/// Useful for tab/content transitions.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.child,
    this.duration = RouticaTheme.animMedium,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}
