class Child {
  final String id;
  final String name;
  final int? age;
  final String robotPreference;
  final int currentDifficultyLevel;

  const Child({
    required this.id,
    required this.name,
    this.age,
    required this.robotPreference,
    required this.currentDifficultyLevel,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
        robotPreference: json['robot_preference'] as String? ?? 'tino',
        currentDifficultyLevel: json['current_difficulty_level'] as int? ?? 1,
      );
}
