import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6FAFB),
            AppThemeColors.haze,
            Color(0xFFE8F1F4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -80,
            child: _glow(
              size: 300,
              color: const Color(0x1424C7B6),
            ),
          ),
          Positioned(
            top: 120,
            right: -100,
            child: _glow(
              size: 280,
              color: const Color(0x182483F0),
            ),
          ),
          Positioned(
            bottom: -120,
            left: 40,
            child: _glow(
              size: 260,
              color: const Color(0x16F08A24),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -40,
            child: Transform.rotate(
              angle: 0.48,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(72),
                  color: AppThemeColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                    AppThemeColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
