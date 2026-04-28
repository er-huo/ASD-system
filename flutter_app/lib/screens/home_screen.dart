import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/activity_card.dart';
import '../config/constants.dart';

class HomeScreen extends StatelessWidget {
  final String childId;
  const HomeScreen({super.key, required this.childId});

  static const _activities = [
    {'key': 'detective',  'label': '情绪大侦探', 'emoji': '🕵️', 'color': Color(0xFF42A5F5)},
    {'key': 'match',      'label': '表情连连看', 'emoji': '🔗', 'color': Color(0xFF66BB6A)},
    {'key': 'face_build', 'label': '拼脸大师',  'emoji': '🎭', 'color': Color(0xFFAB47BC)},
    {'key': 'social',     'label': '社交小剧场', 'emoji': '🎬', 'color': Color(0xFFEF5350)},
    {'key': 'diary',      'label': '心情日记',  'emoji': '📔', 'color': Color(0xFFFFCA28)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('选择今天要玩什么'),
        backgroundColor: const Color(0xFFFFAA00),
        actions: [
          _TherapistLongPressButton(onActivated: () => _showTherapistEntry(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: _activities.map((a) {
            return ActivityCard(
              label: a['label'] as String,
              emoji: a['emoji'] as String,
              color: a['color'] as Color,
              onTap: () => context.go('/train?child_id=$childId&activity=${a['key']}'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTherapistEntry(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('治疗师入口'),
        content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text == kTherapistPassword) {
                Navigator.pop(ctx);
                context.go('/dashboard?child_id=$childId');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码错误')));
              }
            },
            child: const Text('进入'),
          ),
        ],
      ),
    );
  }
}

class _TherapistLongPressButton extends StatefulWidget {
  final VoidCallback onActivated;
  const _TherapistLongPressButton({required this.onActivated});
  @override
  State<_TherapistLongPressButton> createState() => _TherapistLongPressButtonState();
}

class _TherapistLongPressButtonState extends State<_TherapistLongPressButton> {
  Timer? _timer;
  bool _holding = false;

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _holding = true);
    _timer = Timer(const Duration(seconds: 3), () {
      if (_holding) widget.onActivated();
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _timer?.cancel();
    setState(() => _holding = false);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.settings, color: _holding ? Colors.yellow : Colors.white),
        ),
      );
}
