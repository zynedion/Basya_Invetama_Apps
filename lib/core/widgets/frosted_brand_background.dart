import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FrostedBrandBackground extends StatelessWidget {
  const FrostedBrandBackground({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      color: AppTheme.loginCanvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 390).clamp(1.0, 1.7).toDouble();
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -150 * scale,
                top: -110 * scale,
                width: 480 * scale,
                height: 430 * scale,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
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
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
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
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
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
        },
      ),
    ),
  );
}
