import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  double _volume = 0.8;
  int _defaultDifficulty = 1;

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _volume = prefs.getDouble('volume') ?? 0.8;
      _defaultDifficulty = prefs.getInt('default_difficulty') ?? 1;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setDouble('volume', _volume);
    await prefs.setInt('default_difficulty', _defaultDifficulty);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存')));
  }

  Future<void> _resetBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_url');
    if (mounted) context.go('/config');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练设置'), backgroundColor: const Color(0xFFFFAA00)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        SwitchListTile(title: const Text('背景音乐'), value: _musicEnabled, onChanged: (v) => setState(() => _musicEnabled = v)),
        ListTile(
          title: Text('音量: ${(_volume * 100).toInt()}%'),
          subtitle: Slider(value: _volume, onChanged: (v) => setState(() => _volume = v)),
        ),
        ListTile(
          title: const Text('默认难度'),
          trailing: DropdownButton<int>(
            value: _defaultDifficulty,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1级（入门）')),
              DropdownMenuItem(value: 2, child: Text('2级（进阶）')),
              DropdownMenuItem(value: 3, child: Text('3级（挑战）')),
            ],
            onChanged: (v) => setState(() => _defaultDifficulty = v!),
          ),
        ),
        const Divider(),
        ListTile(leading: const Icon(Icons.wifi), title: const Text('重新配置后端地址'), onTap: _resetBackendUrl),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, child: const Text('保存设置')),
      ]),
    );
  }
}
