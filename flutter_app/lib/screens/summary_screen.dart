import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/backend_provider.dart';
import '../config/constants.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final int accuracy;
  final int total;

  const SummaryScreen({
    super.key,
    required this.sessionId,
    required this.accuracy,
    required this.total,
  });

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  List<Map<String, dynamic>> _emotionLogs = [];
  bool _loading = true;

  static const _emotionOrder = [
    'happy', 'surprise', 'neutral', 'confused', 'sad', 'fear', 'angry',
  ];
  static const _emotionLabels = {
    'happy': '开心', 'sad': '伤心', 'angry': '生气',
    'fear': '害怕', 'surprise': '惊讶', 'neutral': '平静', 'confused': '困惑',
  };
  static const _emotionEmoji = {
    'happy': '😊', 'sad': '😢', 'angry': '😠',
    'fear': '😨', 'surprise': '😮', 'neutral': '😐', 'confused': '😕',
  };

  bool get _isDiary => widget.total == 0 && widget.accuracy == 0;

  String get _stars {
    if (_isDiary) return '📔';
    if (widget.accuracy >= 90) return '⭐⭐⭐';
    if (widget.accuracy >= 70) return '⭐⭐';
    return '⭐';
  }

  @override
  void initState() {
    super.initState();
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/report/session/${widget.sessionId}/emotions');
      setState(() {
        _emotionLogs = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // Dominant emotion across the session
  String get _dominantEmotion {
    if (_emotionLogs.isEmpty) return 'neutral';
    final counts = <String, int>{};
    for (final l in _emotionLogs) {
      counts[(l['emotion'] as String)] = (counts[l['emotion']] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // Header
            Text(
              _isDiary ? '📔 心情记录完成！' : '🎉 训练完成！',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(_stars, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            if (!_isDiary) ...[
              Text('正确率：${widget.accuracy}%  ·  共 ${widget.total} 题',
                  style: const TextStyle(fontSize: 20, color: Color(0xFFE65100))),
              const SizedBox(height: 4),
              Text(
                widget.accuracy >= 80 ? '太棒了！继续加油！' : '再练练，你一定可以的！',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ] else
              const Text('谢谢你分享今天的心情 💛',
                  style: TextStyle(fontSize: 20, color: Color(0xFFE65100))),

            const SizedBox(height: 28),

            // Emotion trend chart
            if (!_loading && _emotionLogs.isNotEmpty) ...[
              _buildChartCard(),
              const SizedBox(height: 16),
              _buildEmotionSummary(),
              const SizedBox(height: 16),
            ] else if (_loading)
              const CircularProgressIndicator(color: Color(0xFFFFAA00)),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('回到主页', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAA00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.go('/splash'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('情绪变化曲线', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('训练过程中 AI 检测到的情绪', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ScatterChart(
            ScatterChartData(
              minX: 0,
              maxX: (_emotionLogs.length - 1).toDouble().clamp(1, double.infinity),
              minY: -0.5,
              maxY: _emotionOrder.length - 0.5,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, _) {
                      final idx = value.round();
                      if (idx < 0 || idx >= _emotionOrder.length) return const SizedBox();
                      final e = _emotionOrder[idx];
                      return Text(
                        '${_emotionEmoji[e] ?? ''} ${_emotionLabels[e] ?? e}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              scatterSpots: _emotionLogs.asMap().entries.map((entry) {
                final i = entry.key;
                final log = entry.value;
                final emotion = log['emotion'] as String;
                final yIdx = _emotionOrder.indexOf(emotion);
                final color = kEmotionColors[emotion] ?? Colors.grey;
                final conf = (log['confidence'] as num).toDouble();
                return ScatterSpot(
                  i.toDouble(),
                  yIdx < 0 ? 0 : yIdx.toDouble(),
                  dotPainter: FlDotCirclePainter(
                    radius: 6 + conf * 4,
                    color: color.withValues(alpha: 0.7),
                    strokeWidth: 1.5,
                    strokeColor: color,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmotionSummary() {
    final counts = <String, int>{};
    for (final l in _emotionLogs) {
      counts[l['emotion'] as String] = (counts[l['emotion']] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = _emotionLogs.length;
    final dominant = _dominantEmotion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('本次主要情绪', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(_emotionEmoji[dominant] ?? '', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 4),
          Text(
            _emotionLabels[dominant] ?? dominant,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: kEmotionColors[dominant] ?? Colors.orange,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ...sorted.take(4).map((entry) {
          final e = entry.key;
          final pct = entry.value / total;
          final color = kEmotionColors[e] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Text(_emotionEmoji[e] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(_emotionLabels[e] ?? e,
                    style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          );
        }),
      ]),
    );
  }
}
