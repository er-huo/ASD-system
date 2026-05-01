import 'package:flutter/material.dart';
import 'package:startalk_asd/config/activity_catalog.dart';
import 'package:startalk_asd/config/forest_theme.dart';
import 'package:startalk_asd/widgets/activity_illustration.dart';

class ActivityCard extends StatelessWidget {
  final String activityKey;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.activityKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activity = ActivityCatalog.byKey(activityKey);
    if (activity == null) {
      return const SizedBox.shrink();
    }

    final accentColor = activity.accentColor;
    final borderColor = Color.lerp(accentColor, ForestPalette.bark, 0.18) ??
        ForestPalette.bark;
    final glowColor = accentColor.withValues(alpha: 0.18);
    final illustrationTint =
        Color.lerp(accentColor, ForestPalette.cream, 0.55) ?? accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.42),
              width: 1.4,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ForestPalette.cream,
                Color.lerp(ForestPalette.cream, accentColor, 0.06) ??
                    ForestPalette.cream,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: ForestPalette.bark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 134,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: ActivityIllustration(
                    activityKey: activity.key,
                    width: 116,
                    height: 116,
                    alignment: Alignment.center,
                    fallbackColor: illustrationTint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  activity.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ForestPalette.bark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activity.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ForestPalette.bark.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
