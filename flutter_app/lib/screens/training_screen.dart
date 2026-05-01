import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/activity_catalog.dart';
import '../config/constants.dart';
import '../config/forest_theme.dart';
import '../models/question.dart';
import '../providers/backend_provider.dart';
import '../widgets/activity_illustration.dart';
import '../widgets/camera_overlay_stub.dart'
    if (dart.library.html) '../widgets/camera_overlay.dart';
import '../widgets/decorated_card.dart';
import '../widgets/emotion_button.dart';
import '../widgets/hint_card.dart';
import '../widgets/page_background.dart';
import '../widgets/section_title.dart';
import '../widgets/soft_status_badge.dart';
import '../widgets/tino_robot.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  final String childId;
  final String activityType;

  const TrainingScreen({
    super.key,
    required this.childId,
    required this.activityType,
  });

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  String? _sessionId;
  Question? _currentQuestion;
  int _difficulty = 1;
  int _questionIndex = 0;
  int? _selectedChoice;
  bool _hintShown = false;
  bool _showHint = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _tinoEmotion = 'happy';

  String? _selectedDiaryEmotion;
  bool _diarySubmitted = false;
  late DateTime _questionStartTime;
  Timer? _timeoutTimer;
  final _player = AudioPlayer();

  String? _matchSelectedEmotion;
  Map<String, String?> _faceParts = {};

  static const _elementLabels = {
    'eyes': '眼睛',
    'mouth': '嘴巴',
    'eyebrows': '眉毛',
    'eye_outline': '眼型',
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

  static const _emotionNames = {
    'happy': '开心',
    'sad': '伤心',
    'angry': '生气',
    'fear': '害怕',
    'surprise': '惊讶',
    'neutral': '平静',
    'confused': '困惑',
  };

  static const _scenarioEmoji = {
    'happy': ('🎁', Color(0xFFFFF9C4), '小明收到了生日礼物'),
    'sad': ('🎈', Color(0xFFE3F2FD), '小明的气球飞走了'),
    'angry': ('🧱', Color(0xFFFFEBEE), '小明的积木被推倒了'),
    'fear': ('🌑', Color(0xFFEDE7F6), '小明在黑暗中找不到妈妈'),
    'surprise': ('📦', Color(0xFFE0F7FA), '小明打开了神秘的盒子'),
    'neutral': ('📖', Color(0xFFF5F5F5), '小明在安静地看书'),
    'confused': ('🗺️', Color(0xFFE8EAF6), '小明看着复杂的地图'),
  };

  ActivityDefinition? get _activityDefinition =>
      ActivityCatalog.byKey(widget.activityType);

  String get _activityTitle =>
      _activityDefinition?.label ??
      kActivityLabels[widget.activityType] ??
      '训练中';

  String get _progressLabel => widget.activityType == 'diary'
      ? '心情记录'
      : '第${_questionIndex + 1}题 / 共$kQuestionsPerSession题';

  bool get _allPartsSelected {
    final q = _currentQuestion;
    if (q == null || q.elements == null) return false;
    return q.elements!.every((e) => _faceParts[e] != null);
  }

  bool get _faceBuildIsCorrect {
    final q = _currentQuestion;
    if (q == null || q.elements == null) return false;
    return q.elements!.every((e) => _faceParts[e] == q.correctAnswer);
  }

  String get _assembledEmotion {
    final counts = <String, int>{};
    for (final emotion in _faceParts.values) {
      if (emotion == null) continue;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'neutral';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultDifficulty = prefs.getInt('default_difficulty') ?? 1;
    try {
      final api = ref.read(apiServiceProvider);
      final start = await api.startSession(
        childId: widget.childId,
        activityType: widget.activityType,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = start.sessionId;
        _currentQuestion = start.firstQuestion;
        _difficulty = start.difficulty ?? defaultDifficulty;
        _loading = false;
        _questionStartTime = DateTime.now();
      });
      _startTimeoutTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    if (_difficulty == 1) return;
    final seconds = _difficulty == 2 ? 8 : 5;
    _timeoutTimer = Timer(Duration(seconds: seconds), _onTimeout);
  }

  void _onTimeout() {
    if (_currentQuestion != null) {
      final q = _currentQuestion!;
      final wrongChoice = q.choices.firstWhere(
        (c) => c != q.correctAnswer,
        orElse: () => q.choices.last,
      );
      _submitAnswer(wrongChoice, timedOut: true);
    }
  }

  Future<void> _submitAnswer(String choice, {bool timedOut = false}) async {
    if (_submitting) return;
    _submitting = true;
    _timeoutTimer?.cancel();
    final q = _currentQuestion!;
    final responseMs =
        DateTime.now().difference(_questionStartTime).inMilliseconds;
    setState(() {
      _selectedChoice = q.choices.indexOf(choice);
    });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.submitAnswer(
        sessionId: _sessionId!,
        emotionTarget: q.emotionTarget,
        userResponse: choice,
        responseMs: responseMs,
        hintShown: _hintShown,
      );
      if (!mounted) {
        _submitting = false;
        return;
      }
      final audioPath =
          result.isCorrect ? kEmotionAudio[q.emotionTarget] : kAudioWrong;
      if (audioPath != null) {
        try {
          await _player.setAsset(audioPath);
          await _player.play();
        } catch (_) {}
      }
      if (result.adaptiveAction == 'hint' && !_showHint) {
        setState(() {
          _showHint = true;
          _hintShown = true;
        });
        _submitting = false;
        return;
      }
      setState(() {
        _tinoEmotion = result.isCorrect ? q.emotionTarget : 'angry';
        _difficulty = result.difficulty;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) {
        _submitting = false;
        return;
      }
      _questionIndex++;
      if (_questionIndex >= kQuestionsPerSession ||
          result.nextQuestion == null) {
        _submitting = false;
        await _endSession();
      } else {
        setState(() {
          _currentQuestion = result.nextQuestion;
          _selectedChoice = null;
          _hintShown = false;
          _showHint = false;
          _tinoEmotion = 'happy';
          _questionStartTime = DateTime.now();
        });
        _submitting = false;
        _startTimeoutTimer();
      }
    } catch (e) {
      if (!mounted) {
        _submitting = false;
        return;
      }
      setState(() {
        _error = e.toString();
      });
      _submitting = false;
    }
  }

  Future<void> _selectDiaryEmotion(String emotion) async {
    if (_diarySubmitted) return;
    setState(() {
      _selectedDiaryEmotion = emotion;
      _tinoEmotion = emotion;
      _diarySubmitted = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    await _endSession();
  }

  Future<void> _submitMatchAnswer(String choice) async {
    setState(() {
      _matchSelectedEmotion = choice;
    });
    await _submitAnswer(choice);
    if (mounted) {
      setState(() {
        _matchSelectedEmotion = null;
      });
    }
  }

  void _syncFaceParts(List<String> elements) {
    final sameKeys = _faceParts.length == elements.length &&
        elements.every(_faceParts.containsKey);
    if (!sameKeys) {
      _faceParts = {for (final e in elements) e: null};
    }
  }

  Future<void> _submitFaceBuild() async {
    final q = _currentQuestion!;
    final answer = _faceBuildIsCorrect ? q.correctAnswer : _assembledEmotion;
    await _submitAnswer(answer);
    if (mounted) {
      setState(() {
        _faceParts = {};
      });
    }
  }

  Future<void> _endSession() async {
    Map<String, dynamic> summary = {};
    try {
      summary = await ref.read(apiServiceProvider).endSession(_sessionId!);
    } catch (_) {}
    if (mounted) {
      final acc = ((summary['accuracy'] as num?)?.toDouble() ?? 0.0);
      final total = summary['total_questions'] as int? ?? _questionIndex;
      context.go(
        '/summary?session_id=$_sessionId&accuracy=${(acc * 100).toStringAsFixed(0)}&total=$total',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildStateShell(
        title: '正在准备今天的训练',
        subtitle: '伙伴正在整理题目，请稍等一下。',
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildStateShell(
        title: '暂时没能开始训练',
        subtitle: '我们可以稍后再试一次。',
        child: SoftStatusBadge(
          label: '错误: $_error',
          icon: Icons.error_outline,
          backgroundColor: ForestPalette.berry.withValues(alpha: 0.16),
          foregroundColor: ForestPalette.berry,
        ),
      );
    }

    if (widget.activityType == 'diary') {
      return _buildTrainingShell(
        title: _activityTitle,
        subtitle: '温柔记录今天的心情，让伙伴先听听你的感受。',
        companionNote: _diarySubmitted ? '谢谢你把心情告诉我。' : '选一个最像现在感受的心情吧。',
        showCameraStatus: false,
        content: _buildDiaryContent(),
      );
    }

    if (widget.activityType == 'match' && _currentQuestion != null) {
      return _buildTrainingShell(
        title: _activityTitle,
        subtitle: '看看图片，再把合适的情绪轻轻连起来。',
        companionNote: '先看左边线索，再从右边挑一个最像的情绪。',
        showCameraStatus: true,
        content: _buildMatchContent(),
      );
    }

    if (widget.activityType == 'face_build' && _currentQuestion != null) {
      return _buildTrainingShell(
        title: _activityTitle,
        subtitle: '先观察目标表情，再一步步把五官拼出来。',
        companionNote: '慢慢挑选五官，和目标脸对照着来就好。',
        showCameraStatus: true,
        content: _buildFaceBuildContent(),
      );
    }

    if (widget.activityType == 'social' && _currentQuestion != null) {
      return _buildTrainingShell(
        title: _activityTitle,
        subtitle: '跟着小故事感受角色心情，再选出最贴近的答案。',
        companionNote: '先读故事，再想想小明会是什么心情。',
        showCameraStatus: true,
        content: _buildSocialContent(),
      );
    }

    final q = _currentQuestion;
    if (q == null) {
      return _buildStateShell(
        title: _activityTitle,
        subtitle: '还没有拿到题目内容。',
        child: const SoftStatusBadge(
          label: '请稍后重试',
          icon: Icons.hourglass_bottom_rounded,
        ),
      );
    }

    return _buildTrainingShell(
      title: _activityTitle,
      subtitle: '看看问题和图片，再慢慢选出合适的情绪。',
      companionNote: _showHint ? '我已经给你一个小提示啦。' : '看一看线索，再回答我。',
      showCameraStatus: true,
      content: _buildDetectiveContent(q),
    );
  }

  Widget _buildStateShell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Scaffold(
      body: PageBackground(
        topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
        bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SectionTitle(
                    title: title,
                    subtitle: subtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingShell({
    required String title,
    required String subtitle,
    required String companionNote,
    required bool showCameraStatus,
    required Widget content,
  }) {
    final backendUrl =
        ref.watch(backendUrlProvider).valueOrNull ?? 'http://127.0.0.1:8000';

    return Scaffold(
      body: PageBackground(
        topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
        bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(title: title, subtitle: subtitle),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      final companion = _buildCompanionCard(
                        note: companionNote,
                        backendUrl: backendUrl,
                        showCameraStatus: showCameraStatus,
                        robotSize: isWide ? 240 : 172,
                      );
                      final contentCard = DecoratedCard(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: content,
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 24, child: companion),
                            const SizedBox(width: 16),
                            Expanded(flex: 76, child: contentCard),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          companion,
                          const SizedBox(height: 12),
                          Expanded(child: contentCard),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({required String title, required String subtitle}) {
    return DecoratedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            onPressed: () => context.go('/home?child_id=${widget.childId}'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: title, subtitle: subtitle),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SoftStatusBadge(
                      label: _progressLabel,
                      icon: Icons.flag_outlined,
                      backgroundColor:
                          ForestPalette.sunrise.withValues(alpha: 0.28),
                    ),
                    SoftStatusBadge(
                      label: '难度 Lv.$_difficulty',
                      icon: Icons.stacked_bar_chart_rounded,
                      backgroundColor: ForestPalette.sage,
                    ),
                    if (_showHint)
                      SoftStatusBadge(
                        label: '已显示提示',
                        icon: Icons.lightbulb_outline,
                        backgroundColor:
                            ForestPalette.sunrise.withValues(alpha: 0.24),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionCard({
    required String note,
    required String backendUrl,
    required bool showCameraStatus,
    required double robotSize,
  }) {
    final accent = _activityDefinition?.accentColor ?? ForestPalette.fern;

    return DecoratedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(8),
                child: ActivityIllustration(
                  activityKey: widget.activityType,
                  width: 40,
                  height: 40,
                  fallbackColor: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ForestPalette.bark.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: robotSize + 24,
            child: Center(
              child: TinoRobot(
                emotion: _tinoEmotion,
                robotType: 'tino',
                size: robotSize,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SoftStatusBadge(
                label: '伙伴正在陪练',
                icon: Icons.favorite_border,
                backgroundColor: ForestPalette.mist,
              ),
              if (showCameraStatus)
                SoftStatusBadge(
                  label: '摄像头识别中',
                  icon: Icons.videocam_outlined,
                  backgroundColor: ForestPalette.sage,
                ),
            ],
          ),
          if (showCameraStatus && _sessionId != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: CameraOverlay(
                sessionId: _sessionId!,
                backendUrl: backendUrl,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintSection(String emotionTarget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HintCard(
        emotionTarget: emotionTarget,
        onDismiss: () => setState(() {
          _showHint = false;
          _questionStartTime = DateTime.now();
        }),
      ),
    );
  }

  Widget _buildDiaryContent() {
    const emotionLabels = {
      'happy': ('😊', '开心'),
      'sad': ('😢', '伤心'),
      'angry': ('😠', '生气'),
      'fear': ('😨', '害怕'),
      'surprise': ('😮', '惊讶'),
      'neutral': ('😐', '平静'),
      'confused': ('😕', '困惑'),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 520
                ? 3
                : 2;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                title: _diarySubmitted ? '谢谢你告诉我' : '今天你感觉怎么样？',
                subtitle: _diarySubmitted ? '伙伴已经收到你的心情啦。' : '点击最像现在感受的心情卡片。',
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: constraints.maxWidth < 420 ? 1.0 : 1.08,
                children: kEmotions.map((emotion) {
                  final label = emotionLabels[emotion];
                  final isSelected = _selectedDiaryEmotion == emotion;
                  final color = kEmotionColors[emotion] ?? Colors.grey;
                  return GestureDetector(
                    onTap: _diarySubmitted
                        ? null
                        : () => _selectDiaryEmotion(emotion),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? color : color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: color,
                          width: isSelected ? 3 : 1.4,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label?.$1 ?? '',
                              style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 8),
                          Text(
                            label?.$2 ?? emotion,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchContent() {
    final q = _currentQuestion!;
    const emotionLabels = {
      'happy': ('😊', '开心'),
      'sad': ('😢', '伤心'),
      'angry': ('😠', '生气'),
      'fear': ('😨', '害怕'),
      'surprise': ('😮', '惊讶'),
      'neutral': ('😐', '平静'),
      'confused': ('😕', '困惑'),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSideBySide = constraints.maxWidth >= 760;
        final picturePanel = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SoftStatusBadge(
              label: '这是什么表情？',
              icon: Icons.image_search_outlined,
              backgroundColor: ForestPalette.mist,
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _matchSelectedEmotion != null
                      ? (kEmotionColors[_matchSelectedEmotion] ?? Colors.orange)
                      : ForestPalette.sunrise,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ForestPalette.sunrise.withValues(alpha: 0.18),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: _StimulusImage(
                stimuliPath: q.stimuliPath,
                emotionTarget: q.emotionTarget,
                size: showSideBySide ? 240 : 200,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '看清图片后，再从右边找到最像的情绪标签。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ForestPalette.bark.withValues(alpha: 0.72),
                  ),
            ),
          ],
        );

        final answerPanel = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SoftStatusBadge(
              label: '选一个情绪配对',
              icon: Icons.touch_app_outlined,
              backgroundColor: ForestPalette.sage,
            ),
            const SizedBox(height: 14),
            ...q.choices.map((emotion) {
              final label = emotionLabels[emotion];
              final color = kEmotionColors[emotion] ?? Colors.grey;
              final isSelected = _matchSelectedEmotion == emotion;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: _submitting ? null : () => _submitMatchAnswer(emotion),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: color, width: isSelected ? 3 : 1.4),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.28),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(label?.$1 ?? '',
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label?.$2 ?? emotion,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showHint) _buildHintSection(q.emotionTarget),
              if (showSideBySide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: picturePanel),
                    const SizedBox(width: 20),
                    Expanded(child: answerPanel),
                  ],
                )
              else ...[
                picturePanel,
                const SizedBox(height: 20),
                answerPanel,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaceBuildContent() {
    final q = _currentQuestion!;
    final elements = q.elements ?? ['eyes', 'mouth'];
    final choices = q.choices;
    final targetEmotion = q.emotionTarget;
    final targetLabel = _emotionEmoji[targetEmotion] ?? '😊';
    final targetName = _emotionNames[targetEmotion] ?? targetEmotion;

    _syncFaceParts(elements);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackPreview = constraints.maxWidth < 900;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showHint) _buildHintSection(targetEmotion),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '请拼出一张 $targetLabel $targetName 的脸',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (stackPreview)
                Column(
                  children: [
                    _FacePreviewCard(
                      title: '目标脸',
                      subtitle: '$targetLabel $targetName',
                      faceParts: {
                        for (final element in elements) element: targetEmotion
                      },
                      activeElements: elements,
                      accentColor:
                          kEmotionColors[targetEmotion] ?? Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _FacePreviewCard(
                      title: '我拼的脸',
                      subtitle: _allPartsSelected
                          ? '${_emotionEmoji[_assembledEmotion] ?? ''} ${_emotionNames[_assembledEmotion] ?? _assembledEmotion}'
                          : '先把五官选完整',
                      faceParts: _faceParts,
                      activeElements: elements,
                      accentColor:
                          kEmotionColors[_assembledEmotion] ?? Colors.grey,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _FacePreviewCard(
                        title: '目标脸',
                        subtitle: '$targetLabel $targetName',
                        faceParts: {
                          for (final element in elements) element: targetEmotion
                        },
                        activeElements: elements,
                        accentColor:
                            kEmotionColors[targetEmotion] ?? Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FacePreviewCard(
                        title: '我拼的脸',
                        subtitle: _allPartsSelected
                            ? '${_emotionEmoji[_assembledEmotion] ?? ''} ${_emotionNames[_assembledEmotion] ?? _assembledEmotion}'
                            : '先把五官选完整',
                        faceParts: _faceParts,
                        activeElements: elements,
                        accentColor:
                            kEmotionColors[_assembledEmotion] ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              DecoratedCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        color: ForestPalette.sunrise),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '先看目标脸，再给每个部件挑选正确的样子。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ForestPalette.bark.withValues(alpha: 0.76),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...elements.map((element) {
                final label = _elementLabels[element] ?? element;
                final selectedEmotion = _faceParts[element];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DecoratedCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SoftStatusBadge(
                              label: label,
                              backgroundColor: selectedEmotion != null
                                  ? (kEmotionColors[selectedEmotion] ??
                                          Colors.grey)
                                      .withValues(alpha: 0.16)
                                  : ForestPalette.mist,
                              foregroundColor: selectedEmotion != null
                                  ? (kEmotionColors[selectedEmotion] ??
                                      Colors.grey)
                                  : ForestPalette.bark,
                            ),
                            Text(
                              selectedEmotion == null
                                  ? '请选择一种样子'
                                  : '已选：${_emotionEmoji[selectedEmotion] ?? ''} ${_emotionNames[selectedEmotion] ?? selectedEmotion}',
                              style: TextStyle(
                                color: selectedEmotion == null
                                    ? ForestPalette.bark.withValues(alpha: 0.6)
                                    : (kEmotionColors[selectedEmotion] ??
                                        Colors.grey),
                                fontWeight: selectedEmotion == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: choices.map((emotion) {
                            return _FacePartChoiceCard(
                              element: element,
                              emotion: emotion,
                              selected: selectedEmotion == emotion,
                              onTap: _submitting
                                  ? null
                                  : () => setState(() {
                                        _faceParts[element] = emotion;
                                        _tinoEmotion = emotion;
                                      }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_allPartsSelected)
                DecoratedCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _faceBuildIsCorrect
                            ? '太棒了，这张脸和目标脸一样！'
                            : '你现在拼成的是 ${_emotionEmoji[_assembledEmotion] ?? ''} ${_emotionNames[_assembledEmotion] ?? _assembledEmotion}，再对照目标脸试试。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _faceBuildIsCorrect
                              ? Colors.green.shade700
                              : (kEmotionColors[_assembledEmotion] ??
                                  Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle, size: 24),
                          label: Text(
                            _faceBuildIsCorrect ? '确认拼好了！' : '提交这张脸',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ForestPalette.sunrise,
                            foregroundColor: ForestPalette.bark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _submitting ? null : _submitFaceBuild,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialContent() {
    final q = _currentQuestion!;
    final emotion = q.emotionTarget;
    final sceneInfo = _scenarioEmoji[emotion] ??
        ('😶', const Color(0xFFF5F5F5), q.scenario ?? '小明在经历一些事情');
    final sceneEmoji = sceneInfo.$1;
    final sceneBg = sceneInfo.$2;
    final sceneTxt = q.scenario ?? sceneInfo.$3;
    final questionText = q.questionText ?? '小明现在是什么心情？';
    final emotionColor = kEmotionColors[emotion] ?? Colors.orange;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showHint) _buildHintSection(q.emotionTarget),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: sceneBg,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: emotionColor.withValues(alpha: 0.36), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 760;
                final illustration = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(sceneEmoji, style: const TextStyle(fontSize: 62)),
                    const SizedBox(height: 12),
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.33,
                        0.33,
                        0.33,
                        0,
                        0,
                        0.33,
                        0.33,
                        0.33,
                        0,
                        0,
                        0.33,
                        0.33,
                        0.33,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: _StimulusImage(
                        stimuliPath: 'assets/images/pcs/${emotion}_01.png',
                        emotionTarget: emotion,
                        size: 170,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '小明',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ForestPalette.bark.withValues(alpha: 0.64),
                          ),
                    ),
                  ],
                );
                final story = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoftStatusBadge(
                      label: '故事场景',
                      icon: Icons.auto_stories_outlined,
                      backgroundColor: emotionColor.withValues(alpha: 0.16),
                      foregroundColor: emotionColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sceneTxt,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TinoRobot(
                          emotion: _tinoEmotion,
                          robotType: 'tino',
                          size: 64,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                              border: Border.all(
                                color: emotionColor.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              questionText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 4, child: illustration),
                      const SizedBox(width: 18),
                      Expanded(flex: 6, child: story),
                    ],
                  );
                }

                return Column(
                  children: [
                    illustration,
                    const SizedBox(height: 18),
                    story,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: '小明现在的心情是',
            subtitle: '从下面选一个最贴近故事情境的答案。',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = q.choices.length <= 2
                  ? q.choices.length
                  : constraints.maxWidth >= 820
                      ? 4
                      : constraints.maxWidth >= 540
                          ? 3
                          : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                childAspectRatio: constraints.maxWidth < 480 ? 1.25 : 1.6,
                children: q.choices.map((choice) {
                  final color = kEmotionColors[choice] ?? Colors.grey;
                  final emoji = _scenarioEmoji[choice]?.$1 ?? '😶';
                  final name = _emotionNames[choice] ?? choice;
                  return GestureDetector(
                    onTap: _submitting ? null : () => _submitAnswer(choice),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetectiveContent(Question q) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideQuestionLayout = constraints.maxWidth >= 760;
        final answerWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: q.choices.asMap().entries.map((entry) {
            return EmotionButton(
              emotion: entry.value,
              selected: _selectedChoice == entry.key,
              onTap: () => _submitAnswer(entry.value),
            );
          }).toList(),
        );

        final promptCard = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              q.questionText ?? 'Tino 现在是什么心情？',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 18),
            _StimulusImage(
              stimuliPath: q.stimuliPath,
              emotionTarget: q.emotionTarget,
              size: wideQuestionLayout ? 250 : 210,
            ),
          ],
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showHint) _buildHintSection(q.emotionTarget),
              if (wideQuestionLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: promptCard),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SoftStatusBadge(
                            label: '轻轻选一个答案',
                            icon: Icons.psychology_alt_outlined,
                            backgroundColor: ForestPalette.sage,
                          ),
                          const SizedBox(height: 16),
                          answerWrap,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                promptCard,
                const SizedBox(height: 18),
                const SoftStatusBadge(
                  label: '轻轻选一个答案',
                  icon: Icons.psychology_alt_outlined,
                  backgroundColor: ForestPalette.sage,
                ),
                const SizedBox(height: 16),
                answerWrap,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FacePreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, String?> faceParts;
  final List<String> activeElements;
  final Color accentColor;

  const _FacePreviewCard({
    required this.title,
    required this.subtitle,
    required this.faceParts,
    required this.activeElements,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _AssembledFace(
            faceParts: faceParts,
            activeElements: activeElements,
            size: 190,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _FacePartChoiceCard extends StatelessWidget {
  final String element;
  final String emotion;
  final bool selected;
  final VoidCallback? onTap;

  const _FacePartChoiceCard({
    required this.element,
    required this.emotion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = kEmotionColors[emotion] ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: selected ? 2.8 : 1.4),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8)]
              : [],
        ),
        child: Column(
          children: [
            _FacePartIcon(element: element, emotion: emotion, size: 52),
            const SizedBox(height: 8),
            Text(
              '${_StimulusImage.emoji[emotion] ?? ''} ${_emotionDisplayName(emotion)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssembledFace extends StatelessWidget {
  final Map<String, String?> faceParts;
  final List<String> activeElements;
  final double size;
  final Color accentColor;

  const _AssembledFace({
    required this.faceParts,
    required this.activeElements,
    required this.size,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final stroke =
        accentColor == Colors.grey ? const Color(0xFFBDBDBD) : accentColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        shape: BoxShape.circle,
        border: Border.all(color: stroke, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.16,
            child: Container(
              width: size * 0.62,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: stroke.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (activeElements.contains('eye_outline'))
            Positioned(
              top: size * 0.24,
              child: _FacePartRow(
                left: _FacePartIcon(
                  element: 'eye_outline',
                  emotion: faceParts['eye_outline'],
                  size: size * 0.19,
                ),
                right: _FacePartIcon(
                  element: 'eye_outline',
                  emotion: faceParts['eye_outline'],
                  size: size * 0.19,
                ),
                spacing: size * 0.16,
              ),
            ),
          if (activeElements.contains('eyes'))
            Positioned(
              top: size * 0.26,
              child: _FacePartRow(
                left: _FacePartIcon(
                  element: 'eyes',
                  emotion: faceParts['eyes'],
                  size: size * 0.17,
                ),
                right: _FacePartIcon(
                  element: 'eyes',
                  emotion: faceParts['eyes'],
                  size: size * 0.17,
                ),
                spacing: size * 0.18,
              ),
            ),
          if (activeElements.contains('eyebrows'))
            Positioned(
              top: size * 0.13,
              child: _FacePartRow(
                left: _FacePartIcon(
                  element: 'eyebrows',
                  emotion: faceParts['eyebrows'],
                  size: size * 0.19,
                ),
                right: _FacePartIcon(
                  element: 'eyebrows',
                  emotion: faceParts['eyebrows'],
                  size: size * 0.19,
                ),
                spacing: size * 0.16,
              ),
            ),
          if (activeElements.contains('mouth'))
            Positioned(
              bottom: size * 0.2,
              child: _FacePartIcon(
                element: 'mouth',
                emotion: faceParts['mouth'],
                size: size * 0.34,
              ),
            ),
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: size * 0.36,
              height: size * 0.05,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacePartRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;

  const _FacePartRow(
      {required this.left, required this.right, required this.spacing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        left,
        SizedBox(width: spacing),
        right,
      ],
    );
  }
}

class _FacePartIcon extends StatelessWidget {
  final String element;
  final String? emotion;
  final double size;

  const _FacePartIcon(
      {required this.element, required this.emotion, required this.size});

  @override
  Widget build(BuildContext context) {
    final e = emotion ?? 'neutral';
    final color = _facePartColor(e);
    switch (element) {
      case 'eyes':
        return CustomPaint(
            size: Size(size, size * 0.55),
            painter: _EyesPainter(emotion: e, color: color));
      case 'eyebrows':
        return CustomPaint(
            size: Size(size, size * 0.36),
            painter: _EyebrowsPainter(emotion: e, color: color));
      case 'mouth':
        return CustomPaint(
            size: Size(size, size * 0.52),
            painter: _MouthPainter(emotion: e, color: color));
      case 'eye_outline':
        return CustomPaint(
            size: Size(size, size * 0.46),
            painter: _EyeOutlinePainter(emotion: e, color: color));
      default:
        return SizedBox(width: size, height: size * 0.4);
    }
  }
}

String _emotionDisplayName(String emotion) {
  return const {
        'happy': '开心',
        'sad': '伤心',
        'angry': '生气',
        'fear': '害怕',
        'surprise': '惊讶',
        'neutral': '平静',
        'confused': '困惑',
      }[emotion] ??
      emotion;
}

Color _facePartColor(String emotion) {
  return kEmotionColors[emotion] ?? const Color(0xFF666666);
}

class _EyesPainter extends CustomPainter {
  final String emotion;
  final Color color;

  const _EyesPainter({required this.emotion, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pupil = Paint()..color = color;

    final left = Offset(size.width * 0.28, size.height * 0.52);
    final right = Offset(size.width * 0.72, size.height * 0.52);
    final eyeW = size.width * 0.22;
    final eyeH = switch (emotion) {
      'surprise' || 'fear' => size.height * 0.32,
      'sad' => size.height * 0.18,
      'angry' => size.height * 0.16,
      _ => size.height * 0.22,
    };

    for (final center in [left, right]) {
      final rect = Rect.fromCenter(center: center, width: eyeW, height: eyeH);
      canvas.drawOval(rect, paint);
      canvas.drawOval(rect, stroke);
      if (emotion != 'neutral') {
        canvas.drawCircle(center, size.width * 0.035, pupil);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EyesPainter oldDelegate) =>
      oldDelegate.emotion != emotion || oldDelegate.color != color;
}

class _EyebrowsPainter extends CustomPainter {
  final String emotion;
  final Color color;

  const _EyebrowsPainter({required this.emotion, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = Path();
    final right = Path();
    switch (emotion) {
      case 'happy':
        left.moveTo(size.width * 0.05, size.height * 0.75);
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.35,
            size.width * 0.42, size.height * 0.68);
        right.moveTo(size.width * 0.58, size.height * 0.68);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.35,
            size.width * 0.95, size.height * 0.75);
        break;
      case 'sad':
        left.moveTo(size.width * 0.05, size.height * 0.45);
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.8,
            size.width * 0.42, size.height * 0.35);
        right.moveTo(size.width * 0.58, size.height * 0.35);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.8,
            size.width * 0.95, size.height * 0.45);
        break;
      case 'angry':
        left.moveTo(size.width * 0.05, size.height * 0.25);
        left.lineTo(size.width * 0.42, size.height * 0.75);
        right.moveTo(size.width * 0.58, size.height * 0.75);
        right.lineTo(size.width * 0.95, size.height * 0.25);
        break;
      case 'fear':
        left.moveTo(size.width * 0.05, size.height * 0.55);
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.15,
            size.width * 0.42, size.height * 0.48);
        right.moveTo(size.width * 0.58, size.height * 0.48);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.15,
            size.width * 0.95, size.height * 0.55);
        break;
      case 'surprise':
        left.moveTo(size.width * 0.08, size.height * 0.32);
        left.lineTo(size.width * 0.42, size.height * 0.32);
        right.moveTo(size.width * 0.58, size.height * 0.32);
        right.lineTo(size.width * 0.92, size.height * 0.32);
        break;
      case 'confused':
        left.moveTo(size.width * 0.05, size.height * 0.5);
        left.lineTo(size.width * 0.42, size.height * 0.25);
        right.moveTo(size.width * 0.58, size.height * 0.3);
        right.lineTo(size.width * 0.95, size.height * 0.58);
        break;
      default:
        left.moveTo(size.width * 0.05, size.height * 0.42);
        left.lineTo(size.width * 0.42, size.height * 0.42);
        right.moveTo(size.width * 0.58, size.height * 0.42);
        right.lineTo(size.width * 0.95, size.height * 0.42);
    }
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
  }

  @override
  bool shouldRepaint(covariant _EyebrowsPainter oldDelegate) =>
      oldDelegate.emotion != emotion || oldDelegate.color != color;
}

class _MouthPainter extends CustomPainter {
  final String emotion;
  final Color color;

  const _MouthPainter({required this.emotion, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final path = Path();
    switch (emotion) {
      case 'happy':
        path.moveTo(size.width * 0.12, size.height * 0.45);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.95,
            size.width * 0.88, size.height * 0.45);
        canvas.drawPath(path, stroke);
        break;
      case 'sad':
        path.moveTo(size.width * 0.12, size.height * 0.75);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.12,
            size.width * 0.88, size.height * 0.75);
        canvas.drawPath(path, stroke);
        break;
      case 'angry':
        path.moveTo(size.width * 0.15, size.height * 0.55);
        path.lineTo(size.width * 0.85, size.height * 0.45);
        canvas.drawPath(path, stroke);
        break;
      case 'fear':
        final rect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.58),
          width: size.width * 0.32,
          height: size.height * 0.45,
        );
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
        break;
      case 'surprise':
        final rect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.56),
          width: size.width * 0.26,
          height: size.height * 0.52,
        );
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
        break;
      case 'confused':
        path.moveTo(size.width * 0.15, size.height * 0.62);
        path.lineTo(size.width * 0.35, size.height * 0.52);
        path.lineTo(size.width * 0.52, size.height * 0.66);
        path.lineTo(size.width * 0.72, size.height * 0.52);
        path.lineTo(size.width * 0.85, size.height * 0.58);
        canvas.drawPath(path, stroke);
        break;
      default:
        path.moveTo(size.width * 0.16, size.height * 0.58);
        path.lineTo(size.width * 0.84, size.height * 0.58);
        canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MouthPainter oldDelegate) =>
      oldDelegate.emotion != emotion || oldDelegate.color != color;
}

class _EyeOutlinePainter extends CustomPainter {
  final String emotion;
  final Color color;

  const _EyeOutlinePainter({required this.emotion, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (emotion) {
      case 'surprise':
      case 'fear':
        path.addOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.55),
            width: size.width * 0.62,
            height: size.height * 0.48,
          ),
        );
        break;
      case 'sad':
        path.moveTo(size.width * 0.1, size.height * 0.6);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.9,
            size.width * 0.9, size.height * 0.58);
        break;
      case 'angry':
        path.moveTo(size.width * 0.08, size.height * 0.68);
        path.lineTo(size.width * 0.5, size.height * 0.44);
        path.lineTo(size.width * 0.92, size.height * 0.68);
        break;
      case 'confused':
        path.moveTo(size.width * 0.1, size.height * 0.62);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.46,
            size.width * 0.9, size.height * 0.7);
        break;
      default:
        path.moveTo(size.width * 0.1, size.height * 0.58);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.28,
            size.width * 0.9, size.height * 0.58);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _EyeOutlinePainter oldDelegate) =>
      oldDelegate.emotion != emotion || oldDelegate.color != color;
}

class _StimulusImage extends StatelessWidget {
  final String stimuliPath;
  final String emotionTarget;
  final double size;

  const _StimulusImage({
    required this.stimuliPath,
    required this.emotionTarget,
    this.size = 180,
  });

  static const emoji = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'fear': '😨',
    'surprise': '😮',
    'neutral': '😐',
    'confused': '😕',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        stimuliPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Center(
            child: Text(
              emoji[emotionTarget] ?? '🙂',
              style: TextStyle(fontSize: size * 0.52),
            ),
          );
        },
      ),
    );
  }
}
