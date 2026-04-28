import 'package:flutter/material.dart';

class HintCard extends StatelessWidget {
  final String emotionTarget;
  final VoidCallback onDismiss;

  const HintCard({super.key, required this.emotionTarget, required this.onDismiss});

  static const _hints = {
    'happy':    '注意看嘴角，是不是向上翘的哦～',
    'sad':      '注意看嘴角，是不是向下弯的？',
    'angry':    '注意看眉毛，是不是皱成一团？',
    'fear':     '注意看眼睛，是不是睁得很大？',
    'surprise': '注意看嘴巴，是不是张开了？',
    'neutral':  '这个表情很平静，嘴巴是直的哦。',
    'confused': '注意看眉毛，是不是歪着的？',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        border: Border.all(color: const Color(0xFFFFD600), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFFFFD600), size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(_hints[emotionTarget] ?? '仔细看表情哦！', style: const TextStyle(fontSize: 16))),
          IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
        ],
      ),
    );
  }
}
