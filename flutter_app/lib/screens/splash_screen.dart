import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/child.dart';
import '../providers/backend_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  List<Child> _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final api = ref.read(apiServiceProvider);
      final children = await api.listChildren();
      setState(() { _children = children; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createChild(String robot) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('新建儿童档案'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '孩子的名字')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('创建')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.createChild(name: name, robotPreference: robot);
      await _loadChildren();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 48, bottom: 16),
            child: Text('星语灵境', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
          ),
          const Text('选择你的伙伴', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RobotCard(label: 'Tino（男）', robot: 'tino', color: Colors.blue.shade100, onTap: () => _createChild('tino')),
              const SizedBox(width: 32),
              _RobotCard(label: 'Tina（女）', robot: 'tina', color: Colors.pink.shade100, onTap: () => _createChild('tina')),
            ],
          ),
          const SizedBox(height: 32),
          if (_loading) const CircularProgressIndicator(),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_children.isNotEmpty) ...[
            const Text('已有档案，点击继续', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _children.length,
                itemBuilder: (_, i) {
                  final child = _children[i];
                  return ListTile(
                    leading: const Icon(Icons.person, size: 40, color: Color(0xFFFFAA00)),
                    title: Text(child.name, style: const TextStyle(fontSize: 20)),
                    subtitle: Text('Lv.${child.currentDifficultyLevel} · ${child.robotPreference}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/home?child_id=${child.id}'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RobotCard extends StatelessWidget {
  final String label;
  final String robot;
  final Color color;
  final VoidCallback onTap;
  const _RobotCard({required this.label, required this.robot, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, height: 180,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Colors.orange),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('点我创建', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
