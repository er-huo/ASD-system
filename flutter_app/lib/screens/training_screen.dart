import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/question.dart';
import '../models/session.dart';
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
                Container(width: 160, height: 160,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.face, size: 80, color: Colors.grey)),
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
