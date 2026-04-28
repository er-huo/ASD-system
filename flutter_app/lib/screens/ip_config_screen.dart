import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IpConfigScreen extends StatefulWidget {
  const IpConfigScreen({super.key});
  @override
  State<IpConfigScreen> createState() => _IpConfigScreenState();
}

class _IpConfigScreenState extends State<IpConfigScreen> {
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '8000');
  String? _error;

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (ip.isEmpty || port == null) {
      setState(() => _error = '请填写正确的 IP 和端口');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', 'http://$ip:$port');
    if (mounted) context.go('/splash');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(48),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('连接后端服务器', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: _ipController, decoration: const InputDecoration(labelText: '后端 IP 地址', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _portController, decoration: const InputDecoration(labelText: '端口', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _save, child: const Text('确认连接')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
