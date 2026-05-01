import 'package:flutter/material.dart';
import 'package:startalk_asd/config/activity_catalog.dart';
import 'package:startalk_asd/config/forest_theme.dart';

class ActivityIllustration extends StatelessWidget {
  final String? activityKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Color? fallbackColor;

  const ActivityIllustration({
    super.key,
    required this.activityKey,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallbackColor,
  });

  static String? assetPathFor(String? activityKey) {
    return ActivityCatalog.byKey(activityKey)?.assetPath;
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = assetPathFor(activityKey);

    if (assetPath == null) {
      return _FallbackIllustration(
        width: width,
        height: height,
        color: fallbackColor,
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: width == null ? null : width!.round() * 2,
      cacheHeight: height == null ? null : height!.round() * 2,
      errorBuilder: (_, __, ___) => _FallbackIllustration(
        width: width,
        height: height,
        color: fallbackColor,
      ),
    );
  }
}

class _FallbackIllustration extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;

  const _FallbackIllustration({
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ForestPalette.fern;
    final iconColor = Color.lerp(accent, ForestPalette.bark, 0.35) ??
        ForestPalette.bark;
    final resolvedWidth = width ?? 88;
    final resolvedHeight = height ?? 88;

    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          color: iconColor,
          size:
              (resolvedWidth < resolvedHeight ? resolvedWidth : resolvedHeight) *
                  0.42,
        ),
      ),
    );
  }
}
