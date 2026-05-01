import 'package:flutter/material.dart';
import 'package:startalk_asd/config/forest_theme.dart';

class DecoratedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const DecoratedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
  });

  BorderRadius _resolveBorderRadius(ShapeBorder? shape) {
    if (shape is RoundedRectangleBorder) {
      final radius = shape.borderRadius;
      if (radius is BorderRadius) return radius;
      return const BorderRadius.all(Radius.circular(24));
    }
    return const BorderRadius.all(Radius.circular(24));
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final shape = cardTheme.shape;
    final borderRadius = _resolveBorderRadius(shape);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: ForestPalette.bark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: cardTheme.elevation ?? 0,
        color: (cardTheme.color ?? ForestPalette.cream).withValues(alpha: 0.96),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
