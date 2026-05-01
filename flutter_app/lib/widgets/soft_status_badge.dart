import 'package:flutter/material.dart';
import 'package:startalk_asd/config/forest_theme.dart';

class SoftStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SoftStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? ForestPalette.sage;
    final fgColor = foregroundColor ?? ForestPalette.bark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          key: const Key('soft_status_badge_wrap'),
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, key: const Key('soft_status_badge_icon'), size: 16, color: fgColor),
            Text(
              label,
              key: const Key('soft_status_badge_label'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
