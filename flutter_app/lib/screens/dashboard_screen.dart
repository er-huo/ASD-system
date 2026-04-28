import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../providers/backend_provider.dart';
import '../config/constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String childId;
  const DashboardScreen({super.key, required this.childId});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadReport(); }

  Future<void> _loadReport() async {
    try {
      final api = ref.read(apiServiceProvider);
      final report = await api.getReport(widget.childId);
      setState(() { _report = report; _loading = false; });
    } catch (e) { setState(() { _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据看板'),
        backgroundColor: const Color(0xFFFFAA00),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => context.go('/settings'), tooltip: '训练设置')],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _report == null ? const Center(child: Text('暂无数据'))
          : SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('各情绪正确率', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16), _buildAccuracyChart(),
                const SizedBox(height: 32),
                const Text('BKT 掌握度', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16), _buildBktTable(),
                const SizedBox(height: 32),
                const Text('历史会话', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8), _buildSessionList(),
              ],
            )),
    );
  }

  Widget _buildAccuracyChart() {
    final accuracy = (_report!['accuracy_by_emotion'] as Map<String, dynamic>?) ?? {};
    if (accuracy.isEmpty) return const Text('暂无答题数据');
    final bars = accuracy.entries.map((e) {
      final idx = kEmotions.indexOf(e.key);
      if (idx < 0) return null;
      return BarChartGroupData(x: idx, barRods: [
        BarChartRodData(toY: (e.value as num).toDouble(), color: kEmotionColors[e.key] ?? Colors.grey, width: 28, borderRadius: BorderRadius.circular(4)),
      ]);
    }).whereType<BarChartGroupData>().toList();
    return SizedBox(height: 200, child: BarChart(BarChartData(
      barGroups: bars,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) { final e = kEmotions.elementAtOrNull(v.toInt()); return Text(e ?? '', style: const TextStyle(fontSize: 10)); })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%', style: const TextStyle(fontSize: 10)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      maxY: 1.0, borderData: FlBorderData(show: false),
    )));
  }

  Widget _buildBktTable() {
    final states = (_report!['bkt_states'] as List<dynamic>?) ?? [];
    return Table(border: TableBorder.all(color: Colors.grey.shade300), children: [
      const TableRow(children: [
        Padding(padding: EdgeInsets.all(8), child: Text('情绪', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('掌握概率 P(L)', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text('状态', style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
      ...states.map((s) {
        final p = (s['p_known'] as num).toDouble();
        final mastered = p >= 0.95;
        return TableRow(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(s['emotion'] as String)),
          Padding(padding: const EdgeInsets.all(8), child: Text('${(p * 100).toStringAsFixed(1)}%')),
          Padding(padding: const EdgeInsets.all(8), child: Text(mastered ? '✅ 已掌握' : '📖 学习中',
              style: TextStyle(color: mastered ? Colors.green : Colors.orange))),
        ]);
      }),
    ]);
  }

  Widget _buildSessionList() {
    final sessions = (_report!['sessions'] as List<dynamic>?) ?? [];
    if (sessions.isEmpty) return const Text('暂无训练记录');
    return Column(children: sessions.take(10).map((s) {
      final acc = (s['accuracy'] as num?)?.toDouble();
      return ListTile(
        leading: const Icon(Icons.history, color: Color(0xFFFFAA00)),
        title: Text(s['activity_type'] as String? ?? ''),
        subtitle: Text(s['started_at'] as String? ?? ''),
        trailing: acc != null ? Text('${(acc * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : null,
      );
    }).toList());
  }
}
