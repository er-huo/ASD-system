import 'package:flutter/material.dart';
import '../config/constants.dart';

class EmotionButton extends StatelessWidget {
  final String emotion;
  final VoidCallback onTap;
  final bool selected;

  const EmotionButton({super.key, required this.emotion, required this.onTap, this.selected = false});

  static const _labels = {
    'happy': '😊 开心', 'sad': '😢 伤心', 'angry': '😠 生气',
    'fear': '😨 害怕', 'surprise': '😮 惊讶', 'neutral': '😐 平静', 'confused': '😕 困惑',
  };

  @override
  Widget build(BuildContext context) {
    final color = kEmotionColors[emotion] ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : [],
        ),
        child: Text(_labels[emotion] ?? emotion,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : color)),
      ),
    );
  }
}
