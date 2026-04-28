class Question {
  final String id;
  final String activityType;
  final String emotionTarget;
  final int difficultyLevel;
  final String stimuliType;
  final String stimuliPath;
  final List<String> choices;
  final String correctAnswer;
  final int? nPairs;
  final List<String>? elements;
  final String? scenario;
  final String? questionText;

  const Question({
    required this.id,
    required this.activityType,
    required this.emotionTarget,
    required this.difficultyLevel,
    required this.stimuliType,
    required this.stimuliPath,
    required this.choices,
    required this.correctAnswer,
    this.nPairs,
    this.elements,
    this.scenario,
    this.questionText,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        activityType: json['activity_type'] as String,
        emotionTarget: json['emotion_target'] as String,
        difficultyLevel: json['difficulty_level'] as int,
        stimuliType: json['stimuli_type'] as String,
        stimuliPath: json['stimuli_path'] as String,
        choices: List<String>.from(json['choices'] as List),
        correctAnswer: json['correct_answer'] as String,
        nPairs: json['n_pairs'] as int?,
        elements: (json['elements'] as List?)?.cast<String>(),
        scenario: json['scenario'] as String?,
        questionText: json['question_text'] as String?,
      );
}
