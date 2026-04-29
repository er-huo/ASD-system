import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/question.dart';
import '../providers/backend_provider.dart';
import '../widgets/tino_robot.dart';
import '../widgets/emotion_button.dart';
import '../widgets/hint_card.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  final String childId;
  final String activityType;
  const TrainingScreen({super.key, required this.childId, required this.activityType});
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
  // Diary-specific state
  String? _selectedDiaryEmotion;
  bool _diarySubmitted = false;
  late DateTime _questionStartTime;
  Timer? _timeoutTimer;
  final _player = AudioPlayer();

  @override
  void initState() { super.initState(); _startSession(); }

  @override
  void dispose() { _timeoutTimer?.cancel(); _player.dispose(); super.dispose(); }

  Future<void> _startSession() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultDifficulty = prefs.getInt('default_difficulty') ?? 1;
    try {
      final api = ref.read(apiServiceProvider);
      final start = await api.startSession(childId: widget.childId, activityType: widget.activityType);
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
      setState(() { _error = e.toString(); _loading = false; });
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
      final wrongChoice = q.choices.firstWhere((c) => c != q.correctAnswer, orElse: () => q.choices.last);
      _submitAnswer(wrongChoice, timedOut: true);
    }
  }

  Future<void> _submitAnswer(String choice, {bool timedOut = false}) async {
    if (_submitting) return;  // double-tap guard
    _submitting = true;
    _timeoutTimer?.cancel();
    final q = _currentQuestion!;
    final responseMs = DateTime.now().difference(_questionStartTime).inMilliseconds;
    setState(() { _selectedChoice = q.choices.indexOf(choice); });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.submitAnswer(
        sessionId: _sessionId!, emotionTarget: q.emotionTarget,
        userResponse: choice, responseMs: responseMs, hintShown: _hintShown);
      if (!mounted) { _submitting = false; return; }
      final audioPath = result.isCorrect
          ? kEmotionAudio[q.emotionTarget]  // 答对：播放对应情绪音乐
          : kAudioWrong;                     // 答错：播放轻柔提示音
      if (audioPath != null) {
        try { await _player.setAsset(audioPath); await _player.play(); } catch (_) {}
      }
      if (result.adaptiveAction == 'hint' && !_showHint) {
        setState(() { _showHint = true; _hintShown = true; });
        _submitting = false;
        return;
      }
      setState(() {
        _tinoEmotion = result.isCorrect ? q.emotionTarget : 'angry';
        _difficulty = result.difficulty;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) { _submitting = false; return; }
      _questionIndex++;
      if (_questionIndex >= kQuestionsPerSession || result.nextQuestion == null) {
        _submitting = false;
        await _endSession();
      } else {
        setState(() {
          _currentQuestion = result.nextQuestion;
          _selectedChoice = null; _hintShown = false; _showHint = false;
          _tinoEmotion = 'happy'; _questionStartTime = DateTime.now();
        });
        _submitting = false;
        _startTimeoutTimer();
      }
    } catch (e) {
      if (!mounted) { _submitting = false; return; }
      setState(() { _error = e.toString(); });
      _submitting = false;
    }
  }

  // ── Diary activity ──────────────────────────────────────────────────────────

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

  Widget _buildDiaryScreen() {
    const emotionLabels = {
      'happy':    ('😊', '开心'),
      'sad':      ('😢', '伤心'),
      'angry':    ('😠', '生气'),
      'fear':     ('😨', '害怕'),
      'surprise': ('😮', '惊讶'),
      'neutral':  ('😐', '平静'),
      'confused': ('😕', '困惑'),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('心情日记'),
        backgroundColor: const Color(0xFFFFAA00),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Tino
          TinoRobot(emotion: _tinoEmotion, robotType: 'tino', size: 160),
          const SizedBox(height: 16),
          // Prompt text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _diarySubmitted
                  ? '谢谢你告诉我 😊'
                  : '今天你感觉怎么样？',
              key: ValueKey(_diarySubmitted),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
            ),
          ),
          const SizedBox(height: 8),
          if (!_diarySubmitted)
            const Text('点击你现在的心情', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          // Emotion grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                children: kEmotions.map((emotion) {
                  final label = emotionLabels[emotion];
                  final isSelected = _selectedDiaryEmotion == emotion;
                  final color = kEmotionColors[emotion] ?? Colors.grey;
                  return GestureDetector(
                    onTap: _diarySubmitted ? null : () => _selectDiaryEmotion(emotion),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.15),
                        border: Border.all(color: color, width: isSelected ? 3 : 1.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label?.$1 ?? '', style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 6),
                          Text(
                            label?.$2 ?? emotion,
                            style: TextStyle(
                              fontSize: 14,
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Match activity ───────────────────────────────────────────────────────────

  String? _matchSelectedEmotion;

  Widget _buildMatchScreen() {
    final q = _currentQuestion!;
    const emotionLabels = {
      'happy': ('😊', '开心'), 'sad': ('😢', '伤心'), 'angry': ('😠', '生气'),
      'fear': ('😨', '害怕'), 'surprise': ('😮', '惊讶'),
      'neutral': ('😐', '平静'), 'confused': ('😕', '困惑'),
    };
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('第${_questionIndex + 1}题 / 共$kQuestionsPerSession题  ·  表情连连看'),
        backgroundColor: const Color(0xFFFFAA00),
      ),
      body: Row(children: [
        Expanded(
          flex: 5,
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('这是什么表情？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _matchSelectedEmotion != null
                      ? (kEmotionColors[_matchSelectedEmotion] ?? Colors.orange)
                      : Colors.orange,
                  width: 3,
                ),
                boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.2), blurRadius: 12)],
              ),
              child: _StimulusImage(stimuliPath: q.stimuliPath, emotionTarget: q.emotionTarget),
            ),
            const SizedBox(height: 10),
            const Text('↓ 点右侧标签配对', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
        ),
        const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 28),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: q.choices.map((emotion) {
                final label = emotionLabels[emotion];
                final color = kEmotionColors[emotion] ?? Colors.grey;
                final isSelected = _matchSelectedEmotion == emotion;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: _submitting ? null : () => _submitMatchAnswer(emotion),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color, width: isSelected ? 3 : 1.5),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
                            : [],
                      ),
                      child: Row(children: [
                        Text(label?.$1 ?? '', style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Text(label?.$2 ?? emotion, style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(
          width: 110,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TinoRobot(emotion: _tinoEmotion, robotType: 'tino', size: 100),
          ]),
        ),
      ]),
    );
  }

  Future<void> _submitMatchAnswer(String choice) async {
    setState(() { _matchSelectedEmotion = choice; });
    await _submitAnswer(choice);
    if (mounted) setState(() { _matchSelectedEmotion = null; });
  }

  // ── FaceBuild activity ───────────────────────────────────────────────────────

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

  String get _assembledEmotion {
    final counts = <String, int>{};
    for (final emotion in _faceParts.values) {
      if (emotion == null) continue;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'neutral';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

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

  void _syncFaceParts(List<String> elements) {
    final sameKeys = _faceParts.length == elements.length && elements.every(_faceParts.containsKey);
    if (!sameKeys) {
      _faceParts = {for (final e in elements) e: null};
    }
  }

  Widget _buildFaceBuildScreen() {
    final q = _currentQuestion!;
    final elements = q.elements ?? ['eyes', 'mouth'];
    final choices = q.choices;
    final targetEmotion = q.emotionTarget;
    final targetLabel = _emotionEmoji[targetEmotion] ?? '😊';
    final targetName = _emotionNames[targetEmotion] ?? targetEmotion;

    _syncFaceParts(elements);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('第${_questionIndex + 1}题 / 共$kQuestionsPerSession题  ·  拼脸大师'),
        backgroundColor: const Color(0xFFFFAA00),
      ),
      body: Column(
        children: [
          if (_showHint)
            HintCard(
              emotionTarget: targetEmotion,
              onDismiss: () => setState(() {
                _showHint = false;
                _questionStartTime = DateTime.now();
              }),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('请拼出一张 ', style: TextStyle(fontSize: 20)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kEmotionColors[targetEmotion]?.withValues(alpha: 0.15) ?? Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kEmotionColors[targetEmotion] ?? Colors.orange, width: 2),
                  ),
                  child: Text(
                    '$targetLabel $targetName',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kEmotionColors[targetEmotion] ?? Colors.orange,
                    ),
                  ),
                ),
                const Text(' 的脸', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 12, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _FacePreviewCard(
                                title: '目标脸',
                                subtitle: '$targetLabel $targetName',
                                faceParts: {for (final element in elements) element: targetEmotion},
                                activeElements: elements,
                                accentColor: kEmotionColors[targetEmotion] ?? Colors.orange,
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
                                accentColor: kEmotionColors[_assembledEmotion] ?? Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              const Text('拼脸提示', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                '先看目标脸，再给每个部件挑选正确的样子。',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              TinoRobot(emotion: _tinoEmotion, robotType: 'tino', size: 90),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...elements.map((element) {
                          final label = _elementLabels[element] ?? element;
                          final selectedEmotion = _faceParts[element];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: selectedEmotion != null
                                              ? (kEmotionColors[selectedEmotion] ?? Colors.grey).withValues(alpha: 0.16)
                                              : Colors.grey.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedEmotion == null
                                            ? '请选择一种样子'
                                            : '已选：${_emotionEmoji[selectedEmotion] ?? ''} ${_emotionNames[selectedEmotion] ?? selectedEmotion}',
                                        style: TextStyle(
                                          color: selectedEmotion == null
                                              ? Colors.grey
                                              : (kEmotionColors[selectedEmotion] ?? Colors.grey),
                                          fontWeight: selectedEmotion == null ? FontWeight.normal : FontWeight.w600,
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
                            ),
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
                                        : (kEmotionColors[_assembledEmotion] ?? Colors.orange),
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
                                      backgroundColor: const Color(0xFFFFAA00),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: _submitting ? null : _submitFaceBuild,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // ── Social story activity ─────────────────────────────────────────────────────

  static const _scenarioEmoji = {
    'happy':    ('🎁', Color(0xFFFFF9C4), '小明收到了生日礼物'),
    'sad':      ('🎈', Color(0xFFE3F2FD), '小明的气球飞走了'),
    'angry':    ('🧱', Color(0xFFFFEBEE), '小明的积木被推倒了'),
    'fear':     ('🌑', Color(0xFFEDE7F6), '小明在黑暗中找不到妈妈'),
    'surprise': ('📦', Color(0xFFE0F7FA), '小明打开了神秘的盒子'),
    'neutral':  ('📖', Color(0xFFF5F5F5), '小明在安静地看书'),
    'confused': ('🗺️', Color(0xFFE8EAF6), '小明看着复杂的地图'),
  };

  Widget _buildSocialScreen() {
    final q = _currentQuestion!;
    final emotion = q.emotionTarget;
    final sceneInfo = _scenarioEmoji[emotion] ??
        ('😶', const Color(0xFFF5F5F5), q.scenario ?? '小明在经历一些事情');
    final sceneEmoji = sceneInfo.$1;
    final sceneBg = sceneInfo.$2;
    final sceneTxt = q.scenario ?? sceneInfo.$3;
    final questionText = q.questionText ?? '小明现在是什么心情？';
    final emotionColor = kEmotionColors[emotion] ?? Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('第${_questionIndex + 1}题 / 共$kQuestionsPerSession题  ·  社交小剧场'),
        backgroundColor: const Color(0xFFFFAA00),
      ),
      body: Column(children: [
        // 绘本场景面板
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sceneBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: emotionColor.withValues(alpha: 0.4), width: 2),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              // 左：场景插图区
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // 场景大 emoji
                    Text(sceneEmoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    // PCS 情绪脸（模糊处理不剧透答案）
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: _StimulusImage(
                        stimuliPath: 'assets/images/pcs/${emotion}_01.png',
                        emotionTarget: emotion,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('小明', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ]),
                ),
              ),
              // 右：场景文字描述（绘本旁白）
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: emotionColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('📖 故事', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sceneTxt,
                        style: const TextStyle(fontSize: 22, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      // Tino 旁白气泡
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TinoRobot(emotion: _tinoEmotion, robotType: 'tino', size: 60),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              questionText,
                              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
        // 情绪选项按钮区
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('  小明现在的心情是：',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: q.choices.length <= 3 ? q.choices.length : 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: q.choices.map((choice) {
                      final color = kEmotionColors[choice] ?? Colors.grey;
                      final emoji = _scenarioEmoji[choice]?.$1 ?? '😶';
                      final name = _emotionNames[choice] ?? choice;
                      return GestureDetector(
                        onTap: _submitting ? null : () => _submitAnswer(choice),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(name, style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: color,
                            )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _endSession() async {
    Map<String, dynamic> summary = {};
    try { summary = await ref.read(apiServiceProvider).endSession(_sessionId!); } catch (_) {}
    if (mounted) {
      final acc = ((summary['accuracy'] as num?)?.toDouble() ?? 0.0);
      final total = summary['total_questions'] as int? ?? _questionIndex;
      context.go('/summary?session_id=$_sessionId&accuracy=${(acc * 100).toStringAsFixed(0)}&total=$total');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('错误: $_error')));

    // Diary activity gets its own dedicated UI
    if (widget.activityType == 'diary') return _buildDiaryScreen();

    // Match activity: left image + right label cards
    if (widget.activityType == 'match' && _currentQuestion != null) return _buildMatchScreen();

    // FaceBuild activity: assemble face from feature parts
    if (widget.activityType == 'face_build' && _currentQuestion != null) return _buildFaceBuildScreen();

    // Social story activity: storybook scene panel + emotion choices
    if (widget.activityType == 'social' && _currentQuestion != null) return _buildSocialScreen();
    final q = _currentQuestion;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('第${_questionIndex + 1}题 / 共$kQuestionsPerSession题  ·  难度 Lv.$_difficulty'),
        backgroundColor: const Color(0xFFFFAA00),
      ),
      body: Column(children: [
        if (_showHint && q != null)
          HintCard(emotionTarget: q.emotionTarget, onDismiss: () => setState(() {
              _showHint = false;
              _questionStartTime = DateTime.now(); // reset timer after hint dismissed
            })),
        Expanded(child: Row(children: [
          Expanded(flex: 6, child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              if (q != null) ...[
                Text(q.questionText ?? 'Tino现在是什么心情？',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _StimulusImage(stimuliPath: q.stimuliPath, emotionTarget: q.emotionTarget),
                Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                    children: q.choices.asMap().entries.map((e) {
                      return EmotionButton(emotion: e.value, selected: _selectedChoice == e.key,
                          onTap: () => _submitAnswer(e.value));
                    }).toList()),
              ],
            ]),
          )),
          Expanded(flex: 4, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TinoRobot(emotion: _tinoEmotion, robotType: 'tino', size: 180),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('摄像头识别中', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ])),
        ])),
      ]),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
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
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8)] : [],
        ),
        child: Column(
          children: [
            _FacePartIcon(element: element, emotion: emotion, size: 52),
            const SizedBox(height: 8),
            Text(
              '${_StimulusImage._emoji[emotion] ?? ''} ${_emotionDisplayName(emotion)}',
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
    final stroke = accentColor == Colors.grey ? const Color(0xFFBDBDBD) : accentColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        shape: BoxShape.circle,
        border: Border.all(color: stroke, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
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
                left: _FacePartIcon(element: 'eye_outline', emotion: faceParts['eye_outline'], size: size * 0.19),
                right: _FacePartIcon(element: 'eye_outline', emotion: faceParts['eye_outline'], size: size * 0.19),
                spacing: size * 0.16,
              ),
            ),
          if (activeElements.contains('eyes'))
            Positioned(
              top: size * 0.26,
              child: _FacePartRow(
                left: _FacePartIcon(element: 'eyes', emotion: faceParts['eyes'], size: size * 0.17),
                right: _FacePartIcon(element: 'eyes', emotion: faceParts['eyes'], size: size * 0.17),
                spacing: size * 0.18,
              ),
            ),
          if (activeElements.contains('eyebrows'))
            Positioned(
              top: size * 0.13,
              child: _FacePartRow(
                left: _FacePartIcon(element: 'eyebrows', emotion: faceParts['eyebrows'], size: size * 0.19),
                right: _FacePartIcon(element: 'eyebrows', emotion: faceParts['eyebrows'], size: size * 0.19),
                spacing: size * 0.16,
              ),
            ),
          if (activeElements.contains('mouth'))
            Positioned(
              bottom: size * 0.2,
              child: _FacePartIcon(element: 'mouth', emotion: faceParts['mouth'], size: size * 0.34),
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

  const _FacePartRow({required this.left, required this.right, required this.spacing});

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

  const _FacePartIcon({required this.element, required this.emotion, required this.size});

  @override
  Widget build(BuildContext context) {
    final e = emotion ?? 'neutral';
    final color = _facePartColor(e);
    switch (element) {
      case 'eyes':
        return CustomPaint(size: Size(size, size * 0.55), painter: _EyesPainter(emotion: e, color: color));
      case 'eyebrows':
        return CustomPaint(size: Size(size, size * 0.36), painter: _EyebrowsPainter(emotion: e, color: color));
      case 'mouth':
        return CustomPaint(size: Size(size, size * 0.52), painter: _MouthPainter(emotion: e, color: color));
      case 'eye_outline':
        return CustomPaint(size: Size(size, size * 0.46), painter: _EyeOutlinePainter(emotion: e, color: color));
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
  bool shouldRepaint(covariant _EyesPainter oldDelegate) => oldDelegate.emotion != emotion || oldDelegate.color != color;
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
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.35, size.width * 0.42, size.height * 0.68);
        right.moveTo(size.width * 0.58, size.height * 0.68);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.35, size.width * 0.95, size.height * 0.75);
        break;
      case 'sad':
        left.moveTo(size.width * 0.05, size.height * 0.45);
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.8, size.width * 0.42, size.height * 0.35);
        right.moveTo(size.width * 0.58, size.height * 0.35);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.8, size.width * 0.95, size.height * 0.45);
        break;
      case 'angry':
        left.moveTo(size.width * 0.05, size.height * 0.25);
        left.lineTo(size.width * 0.42, size.height * 0.75);
        right.moveTo(size.width * 0.58, size.height * 0.75);
        right.lineTo(size.width * 0.95, size.height * 0.25);
        break;
      case 'fear':
        left.moveTo(size.width * 0.05, size.height * 0.55);
        left.quadraticBezierTo(size.width * 0.24, size.height * 0.15, size.width * 0.42, size.height * 0.48);
        right.moveTo(size.width * 0.58, size.height * 0.48);
        right.quadraticBezierTo(size.width * 0.76, size.height * 0.15, size.width * 0.95, size.height * 0.55);
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
  bool shouldRepaint(covariant _EyebrowsPainter oldDelegate) => oldDelegate.emotion != emotion || oldDelegate.color != color;
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
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.95, size.width * 0.88, size.height * 0.45);
        canvas.drawPath(path, stroke);
        break;
      case 'sad':
        path.moveTo(size.width * 0.12, size.height * 0.75);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.12, size.width * 0.88, size.height * 0.75);
        canvas.drawPath(path, stroke);
        break;
      case 'angry':
        path.moveTo(size.width * 0.15, size.height * 0.55);
        path.lineTo(size.width * 0.85, size.height * 0.45);
        canvas.drawPath(path, stroke);
        break;
      case 'fear':
        final rect = Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.58), width: size.width * 0.32, height: size.height * 0.45);
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
        break;
      case 'surprise':
        final rect = Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.56), width: size.width * 0.26, height: size.height * 0.52);
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
  bool shouldRepaint(covariant _MouthPainter oldDelegate) => oldDelegate.emotion != emotion || oldDelegate.color != color;
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
        path.addOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.55), width: size.width * 0.62, height: size.height * 0.48));
        break;
      case 'sad':
        path.moveTo(size.width * 0.1, size.height * 0.6);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width * 0.9, size.height * 0.58);
        break;
      case 'angry':
        path.moveTo(size.width * 0.08, size.height * 0.68);
        path.lineTo(size.width * 0.5, size.height * 0.44);
        path.lineTo(size.width * 0.92, size.height * 0.68);
        break;
      case 'confused':
        path.moveTo(size.width * 0.1, size.height * 0.62);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.46, size.width * 0.9, size.height * 0.7);
        break;
      default:
        path.moveTo(size.width * 0.1, size.height * 0.58);
        path.quadraticBezierTo(size.width * 0.5, size.height * 0.28, size.width * 0.9, size.height * 0.58);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _EyeOutlinePainter oldDelegate) => oldDelegate.emotion != emotion || oldDelegate.color != color;
}

// ── 刺激材料展示组件 ────────────────────────────────────────────────────────
// 优先加载 asset 图片，失败时回退到情绪 emoji 大图
class _StimulusImage extends StatelessWidget {
  final String stimuliPath;
  final String emotionTarget;

  const _StimulusImage({required this.stimuliPath, required this.emotionTarget});

  static const _emoji = {
    'happy':    '😊', 'sad':      '😢', 'angry':    '😠',
    'fear':     '😨', 'surprise': '😮', 'neutral':  '😐', 'confused': '😕',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        stimuliPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          // 图片加载失败时显示大 emoji
          return Center(
            child: Text(
              _emoji[emotionTarget] ?? '🙂',
              style: const TextStyle(fontSize: 100),
            ),
          );
        },
      ),
    );
  }
}
