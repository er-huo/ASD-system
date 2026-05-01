import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../config/forest_theme.dart';
import '../providers/backend_provider.dart';
import '../widgets/decorated_card.dart';
import '../widgets/page_background.dart';
import '../widgets/section_title.dart';
import '../widgets/soft_status_badge.dart';

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
    'happy',
    'surprise',
    'neutral',
    'confused',
    'sad',
    'fear',
    'angry',
  ];
  static const _emotionLabels = {
    'happy': '开心',
    'sad': '伤心',
    'angry': '生气',
    'fear': '害怕',
    'surprise': '惊讶',
    'neutral': '平静',
    'confused': '困惑',
  };
  static const _emotionEmoji = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'fear': '😨',
    'surprise': '😮',
    'neutral': '😐',
    'confused': '😕',
  };

  bool get _isDiary => widget.total == 0 && widget.accuracy == 0;

  String get _stars {
    if (_isDiary) return '📔';
    if (widget.accuracy >= 90) return '⭐⭐⭐';
    if (widget.accuracy >= 70) return '⭐⭐';
    return '⭐';
  }

  String get _headline => _isDiary ? '心情记录完成啦' : '今天的训练完成啦';

  String get _companionCopy {
    if (_isDiary) {
      return '谢谢你把今天的心情告诉我，我会继续陪你慢慢认识这些感受。';
    }
    if (widget.accuracy >= 80) {
      return '你刚刚完成得很棒，我们一起把这些小进步都收进森林故事里。';
    }
    return '你已经认真完成了今天的练习，我们下次再一起慢慢试试。';
  }

  @override
  void initState() {
    super.initState();
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data =
          await api.get('/report/session/${widget.sessionId}/emotions');
      if (!mounted) return;
      setState(() {
        _emotionLogs = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _dominantEmotion {
    if (_emotionLogs.isEmpty) return 'neutral';
    final counts = <String, int>{};
    for (final log in _emotionLogs) {
      counts[(log['emotion'] as String)] = (counts[log['emotion']] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
        bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedCard(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stack = constraints.maxWidth < 860;
                        final copy = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SoftStatusBadge(
                              label: _isDiary ? '森林心情日记' : '森林训练总结',
                              icon: _isDiary
                                  ? Icons.auto_stories_outlined
                                  : Icons.celebration_outlined,
                              backgroundColor: ForestPalette.sage,
                            ),
                            const SizedBox(height: 16),
                            SectionTitle(
                              title: _headline,
                              subtitle: _companionCopy,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _stars,
                              style: const TextStyle(fontSize: 44),
                            ),
                            const SizedBox(height: 10),
                            if (!_isDiary) ...[
                              Text(
                                '正确率：${widget.accuracy}% · 共 ${widget.total} 题',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: ForestPalette.bark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.accuracy >= 80
                                    ? '伙伴看见你今天特别认真。'
                                    : '每一次练习都会让你更熟悉这些情绪线索。',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: ForestPalette.bark
                                          .withValues(alpha: 0.74),
                                    ),
                              ),
                            ] else
                              Text(
                                '今天的感受已经好好记录下来了。',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: ForestPalette.bark
                                          .withValues(alpha: 0.74),
                                    ),
                              ),
                          ],
                        );

                        final art = ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            color: ForestPalette.sage.withValues(alpha: 0.18),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/images/ui/report_finish_scene.png',
                              key: const Key('summary_finish_art'),
                              fit: BoxFit.contain,
                              height: stack ? 220 : 260,
                            ),
                          ),
                        );

                        if (stack) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              copy,
                              const SizedBox(height: 20),
                              art,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 6, child: copy),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: art),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_loading && _emotionLogs.isNotEmpty) ...[
                    _buildChartCard(),
                    const SizedBox(height: 16),
                    _buildEmotionSummary(),
                    const SizedBox(height: 16),
                  ] else if (_loading) ...[
                    const DecoratedCard(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: ForestPalette.sunrise)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildActionCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '收好今天的练习',
            subtitle: '准备好了就回到主页，继续下一段森林故事。',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home_rounded),
              label: const Text('回到主页', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ForestPalette.sunrise,
                foregroundColor: ForestPalette.bark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.go('/splash'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '情绪变化曲线',
            subtitle: '训练过程中 AI 检测到的情绪变化。',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_emotionLogs.length - 1)
                    .toDouble()
                    .clamp(1, double.infinity),
                minY: -0.5,
                maxY: _emotionOrder.length - 0.5,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: ForestPalette.bark.withValues(alpha: 0.10),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      getTitlesWidget: (value, _) {
                        final idx = value.round();
                        if (idx < 0 || idx >= _emotionOrder.length) {
                          return const SizedBox();
                        }
                        final emotion = _emotionOrder[idx];
                        return Text(
                          '${_emotionEmoji[emotion] ?? ''} ${_emotionLabels[emotion] ?? emotion}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _emotionLogs.asMap().entries.map((entry) {
                      final yIdx = _emotionOrder
                          .indexOf(entry.value['emotion'] as String);
                      return FlSpot(
                          entry.key.toDouble(), yIdx < 0 ? 0 : yIdx.toDouble());
                    }).toList(),
                    isCurved: false,
                    color: ForestPalette.sunrise.withValues(alpha: 0.55),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final emotion =
                            _emotionLogs[index]['emotion'] as String;
                        final color = kEmotionColors[emotion] ?? Colors.grey;
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSummary() {
    final counts = <String, int>{};
    for (final log in _emotionLogs) {
      counts[log['emotion'] as String] = (counts[log['emotion']] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _emotionLogs.length;
    final dominant = _dominantEmotion;

    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  title: '本次主要情绪',
                  subtitle: '看看训练过程中最常出现的情绪。',
                ),
              ),
              const SizedBox(width: 12),
              SoftStatusBadge(
                label:
                    '${_emotionEmoji[dominant] ?? ''} ${_emotionLabels[dominant] ?? dominant}',
                backgroundColor:
                    (kEmotionColors[dominant] ?? ForestPalette.sunrise)
                        .withValues(alpha: 0.16),
                foregroundColor: kEmotionColors[dominant] ?? ForestPalette.bark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sorted.take(4).map((entry) {
            final emotion = entry.key;
            final pct = entry.value / total;
            final color = kEmotionColors[emotion] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(_emotionEmoji[emotion] ?? '',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      _emotionLabels[emotion] ?? emotion,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 12,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: ForestPalette.bark.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
