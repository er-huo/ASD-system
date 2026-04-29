import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SummaryScreen extends StatelessWidget {
  final String sessionId;
  final int accuracy;   // percentage 0-100; -1 means diary (no scoring)
  final int total;

  const SummaryScreen({super.key, required this.sessionId, required this.accuracy, required this.total});

  bool get _isDiary => total == 0 && accuracy == 0;

  String get _stars {
    if (_isDiary) return '📔';
    if (accuracy >= 90) return '⭐⭐⭐';
    if (accuracy >= 70) return '⭐⭐';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          _isDiary ? '📔 心情记录完成！' : '🎉 训练完成！',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(_stars, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        if (_isDiary)
          const Text('谢谢你分享今天的心情 💛',
              style: TextStyle(fontSize: 20, color: Color(0xFFE65100)))
        else ...[
          Text('正确率：$accuracy%  ·  共 $total 题',
              style: const TextStyle(fontSize: 22, color: Color(0xFFE65100))),
          const SizedBox(height: 8),
          Text(accuracy >= 80 ? '太棒了！继续加油！' : '再练练，你一定可以的！',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
        const SizedBox(height: 40),
        ElevatedButton.icon(
          icon: const Icon(Icons.home), label: const Text('回到主页'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFAA00),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          onPressed: () => context.go('/splash'),
        ),
      ])),
    );
  }
}
