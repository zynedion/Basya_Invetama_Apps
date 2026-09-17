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
    duration: const Duration(seconds: 14),
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
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
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
                progress: Curves.easeInOutSine.transform(_controller.value),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _GlowComposition extends StatelessWidget {
  const _GlowComposition({required this.scale, this.progress = 0});

  final double scale;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final centered = (progress * 2) - 1;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: -150 * scale,
          top: -110 * scale,
          width: 480 * scale,
          height: 430 * scale,
          child: Transform.translate(
            offset: Offset(24 * centered * scale, 12 * progress * scale),
            child: Transform.scale(
              scale: 1 + (0.045 * progress),
              child: const _Glow(
                colors: [
                  Color(0x955FDEA9),
                  Color(0x67A4EDD2),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.5, 1],
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
            offset: Offset(-20 * centered * scale, 9 * (1 - progress) * scale),
            child: Transform.scale(
              scale: 1.045 - (0.045 * progress),
              child: const _Glow(
                colors: [
                  Color(0x78008579),
                  Color(0x5467D3C1),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.52, 1],
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
            offset: Offset(10 * centered * scale, -8 * progress * scale),
            child: Opacity(
              opacity: 0.92 + (0.08 * progress),
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
