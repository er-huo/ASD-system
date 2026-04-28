import 'question.dart';

class SessionStart {
  final String sessionId;
  final Question? firstQuestion;
  final int? difficulty;

  const SessionStart({required this.sessionId, this.firstQuestion, this.difficulty});

  factory SessionStart.fromJson(Map<String, dynamic> json) => SessionStart(
        sessionId: json['session_id'] as String,
        firstQuestion: json['first_question'] != null
            ? Question.fromJson(json['first_question'] as Map<String, dynamic>)
            : null,
        difficulty: json['difficulty'] as int?,
      );
}

class AnswerResult {
  final bool isCorrect;
  final String adaptiveAction;
  final Question? nextQuestion;
  final int difficulty;

  const AnswerResult({
    required this.isCorrect,
    required this.adaptiveAction,
    this.nextQuestion,
    required this.difficulty,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        isCorrect: json['is_correct'] as bool,
        adaptiveAction: json['adaptive_action'] as String,
        nextQuestion: json['next_question'] != null
            ? Question.fromJson(json['next_question'] as Map<String, dynamic>)
            : null,
        difficulty: json['difficulty'] as int,
      );
}

class EmotionFrame {
  final String? emotion;
  final double confidence;
  final String source;

  const EmotionFrame({this.emotion, required this.confidence, required this.source});

  factory EmotionFrame.fromJson(Map<String, dynamic> json) => EmotionFrame(
        emotion: json['emotion'] as String?,
        confidence: (json['confidence'] as num).toDouble(),
        source: json['source'] as String? ?? 'fused',
      );
}
