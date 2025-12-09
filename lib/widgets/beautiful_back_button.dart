import 'package:flutter/material.dart';

/// Beautiful Back Button Widget - Reusable across all screens
/// A beautiful glassmorphic back button with gradient border and shadow
class BeautifulBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;
  final double size;
  final bool isDarkMode;

  const BeautifulBackButton({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x33FFFFFF),
    this.size = 48,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF6366F1).withValues(alpha: 0.3),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (!isDarkMode)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner glow effect
            Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Light theme back button for light colored screens
class LightBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const LightBackButton({
    super.key,
    this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF333333),
          size: 20,
        ),
      ),
    );
  }
}

/// Gradient back button with custom colors
class GradientBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final double size;

  const GradientBackButton({
    super.key,
    this.onTap,
    this.gradientColors = const [Color(0xFF8C52FF), Color(0xFF00C9FF)],
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
