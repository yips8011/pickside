import 'package:flutter/material.dart';
import 'zhande_refresh_constants.dart';

/// Pure visual widget that renders the 站/队 brand animation content.
///
/// Receives pre-computed values from [ZhandeRefreshIndicator].
/// Does NOT manage any state or animation controllers.
class ZhandeRefreshHeader extends StatelessWidget {
  const ZhandeRefreshHeader({
    required this.textProgress,
    required this.textScale,
    required this.successOpacity,
    required this.bounceScale,
    required this.breathingScale,
    required this.breathingOpacity,
    required this.glowValue,
    required this.isRefreshing,
    required this.isSuccess,
    required this.completeMessage,
    super.key,
  });

  /// Pull progress: 0.0 (collapsed) → 1.0 (trigger reached).
  final double textProgress;

  /// Text scale from pull progress.
  final double textScale;

  /// Opacity of success message (0.0 or 1.0).
  final double successOpacity;

  /// Current bounce animation scale value.
  final double bounceScale;

  /// Current breathing animation scale value.
  final double breathingScale;

  /// Current breathing animation opacity value.
  final double breathingOpacity;

  /// Current glow animation value (0.0 → ~0.25 → 0.0).
  final double glowValue;

  final bool isRefreshing;
  final bool isSuccess;
  final String completeMessage;

  @override
  Widget build(BuildContext context) {
    // Glow opacity: parabolic pulse peaking at 0.6
    final glowNormalized = glowValue.clamp(0.0, 1.0);
    final glowOpacity = glowNormalized > 0
        ? (4.0 * glowNormalized * (1.0 - glowNormalized)) * 0.6
        : 0.0;

    // Distance between 站 and 队: 70px → 0px
    final distance = kZhandeTextMaxOffset * (1.0 - textProgress);

    // Combined scale from pull + bounce + breathing
    final scale = textScale *
        bounceScale *
        (isRefreshing ? breathingScale : 1.0);

    // Text opacity: during refreshing, use breathing opacity
    final opacity = isRefreshing ? breathingOpacity : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 站队 text row
        Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: glowOpacity > 0
                ? [
                    BoxShadow(
                      color: kZhandeGreenColor.withValues(alpha: glowOpacity),
                      blurRadius: 50,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(-distance, 0),
                    child: Text(
                      '\u7ad9',
                      style: TextStyle(
                        fontFamily: 'SmileySans',
                        fontSize: kZhandeTextFontSize,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(distance, 0),
                    child: Text(
                      '\u961f',
                      style: TextStyle(
                        fontFamily: 'SmileySans',
                        fontSize: kZhandeTextFontSize,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Success message area (always occupies space to prevent layout shift)
        SizedBox(
          height: 20,
          child: AnimatedOpacity(
            opacity: successOpacity,
            duration: const Duration(milliseconds: 200),
            child: Text(
              completeMessage,
              style: const TextStyle(
                color: kZhandeSuccessTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color get _textColor {
    if (isRefreshing || isSuccess) {
      return Color.lerp(kZhandeGrayColor, kZhandeGreenColor, _colorProgress)!;
    }
    return kZhandeGrayColor;
  }

  double get _colorProgress {
    if (isRefreshing) {
      // Color smoothly transitions over ~200ms of breathing cycle
      return (breathingScale - 0.90) / (1.05 - 0.90);
    }
    if (isSuccess) return 1.0;
    return 0.0;
  }
}
