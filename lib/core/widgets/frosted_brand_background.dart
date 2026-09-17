import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FrostedBrandBackground extends StatefulWidget {
  const FrostedBrandBackground({super.key, this.animated = true});

  /// Set to false to restore the original static background composition.
  final bool animated;

  @override
  State<FrostedBrandBackground> createState() => _FrostedBrandBackgroundState();
}

class _FrostedBrandBackgroundState extends State<FrostedBrandBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  bool _reduceMotion = false;

  bool get _shouldAnimate => widget.animated && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant FrostedBrandBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animated != widget.animated) _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAnimation();
    } else {
      _controller.stop();
    }
  }

  void _syncAnimation() {
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: ColoredBox(
        color: AppTheme.loginCanvas,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 390)
                .clamp(1.0, 1.7)
                .toDouble();
            if (!_shouldAnimate) return _GlowComposition(scale: scale);
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _GlowComposition(
                scale: scale,
                progress: _controller.value,
                animated: true,
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _GlowComposition extends StatelessWidget {
  const _GlowComposition({
    required this.scale,
    this.progress = 0,
    this.animated = false,
  });

  final double scale;
  final double progress;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi * 2;
    final motion = animated ? 1.0 : 0.0;
    final primaryX = math.sin(angle) * motion;
    final primaryY = math.cos(angle) * motion;
    final secondaryX = math.sin(angle + (math.pi * 0.8)) * motion;
    final secondaryY = math.cos(angle + (math.pi * 0.8)) * motion;
    final tertiaryX = math.sin(angle + (math.pi * 1.35)) * motion;
    final tertiaryY = math.cos(angle + (math.pi * 1.35)) * motion;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: -150 * scale,
          top: -110 * scale,
          width: 480 * scale,
          height: 430 * scale,
          child: Transform.translate(
            offset: Offset(58 * primaryX * scale, 30 * primaryY * scale),
            child: Transform.scale(
              scale: 1 + (0.075 * ((primaryY + motion) / 2)),
              child: Opacity(
                opacity: animated ? 0.82 + (0.18 * ((primaryX + 1) / 2)) : 1,
                child: _Glow(
                  colors: animated
                      ? const [
                          Color(0xA85FDEA9),
                          Color(0x72A4EDD2),
                          Color(0x00FFFFFF),
                        ]
                      : const [
                          Color(0x955FDEA9),
                          Color(0x67A4EDD2),
                          Color(0x00FFFFFF),
                        ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -190 * scale,
          top: -90 * scale,
          width: 410 * scale,
          height: 390 * scale,
          child: Transform.translate(
            offset: Offset(52 * secondaryX * scale, 28 * secondaryY * scale),
            child: Transform.scale(
              scale: 1 + (0.07 * ((secondaryX + motion) / 2)),
              child: Opacity(
                opacity: animated ? 0.84 + (0.16 * ((secondaryY + 1) / 2)) : 1,
                child: _Glow(
                  colors: animated
                      ? const [
                          Color(0x8A008579),
                          Color(0x6267D3C1),
                          Color(0x00FFFFFF),
                        ]
                      : const [
                          Color(0x78008579),
                          Color(0x5467D3C1),
                          Color(0x00FFFFFF),
                        ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -115 * scale,
          bottom: -40 * scale,
          width: 330 * scale,
          height: 330 * scale,
          child: Transform.translate(
            offset: Offset(34 * tertiaryX * scale, 22 * tertiaryY * scale),
            child: Opacity(
              opacity: animated ? 0.78 + (0.22 * ((tertiaryX + 1) / 2)) : 1,
              child: const _Glow(
                colors: [
                  Color(0x385FDEA9),
                  Color(0x24B9F3DE),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x24FFFFFF),
                  Color(0x68FFFFFF),
                  Color(0xD4FFFFFF),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.colors, required this.stops});

  final List<Color> colors;
  final List<double> stops;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(colors: colors, stops: stops),
    ),
  );
}
