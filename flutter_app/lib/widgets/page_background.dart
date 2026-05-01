import 'package:flutter/material.dart';
import 'package:startalk_asd/config/forest_theme.dart';

class PageBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? topDecorativeAssetPath;
  final String? bottomDecorativeAssetPath;

  const PageBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.topDecorativeAssetPath,
    this.bottomDecorativeAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ForestPalette.mist,
            ForestPalette.sage,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: topDecorativeAssetPath == null
                ? _GlowCircle(
                    size: 140,
                    color: ForestPalette.sunrise.withValues(alpha: 0.18),
                  )
                : _DecorativeAsset(
                    assetPath: topDecorativeAssetPath!,
                    width: 140,
                  ),
          ),
          Positioned(
            left: -30,
            bottom: 40,
            child: bottomDecorativeAssetPath == null
                ? _GlowCircle(
                    size: 120,
                    color: ForestPalette.fern.withValues(alpha: 0.16),
                  )
                : _DecorativeAsset(
                    assetPath: bottomDecorativeAssetPath!,
                    width: 120,
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeAsset extends StatelessWidget {
  final String assetPath;
  final double width;

  const _DecorativeAsset({required this.assetPath, required this.width});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Image.asset(
          assetPath,
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
