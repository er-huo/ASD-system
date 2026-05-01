import 'package:flutter/material.dart';
import 'package:startalk_asd/config/forest_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.left,
  });

  CrossAxisAlignment get _crossAxisAlignment {
    switch (textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.justify:
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: textTheme.headlineSmall?.copyWith(
            color: ForestPalette.bark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: textTheme.bodyMedium?.copyWith(
              color: ForestPalette.bark.withValues(alpha: 0.78),
            ),
          ),
        ],
      ],
    );
  }
}
