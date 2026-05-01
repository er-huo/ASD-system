import 'package:flutter/material.dart';

class ActivityDefinition {
  final String key;
  final String label;
  final String subtitle;
  final Color accentColor;
  final String assetPath;

  const ActivityDefinition({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.assetPath,
  });
}

class ActivityCatalog {
  static const detective = ActivityDefinition(
    key: 'detective',
    label: '情绪大侦探',
    subtitle: '观察线索，找到情绪',
    accentColor: Color(0xFF42A5F5),
    assetPath: 'assets/images/activities/detective.png',
  );

  static const match = ActivityDefinition(
    key: 'match',
    label: '表情连连看',
    subtitle: '把表情和情境轻轻连起来',
    accentColor: Color(0xFF66BB6A),
    assetPath: 'assets/images/activities/match.png',
  );

  static const faceBuild = ActivityDefinition(
    key: 'face_build',
    label: '拼脸大师',
    subtitle: '拼出五官，认识表情变化',
    accentColor: Color(0xFFAB47BC),
    assetPath: 'assets/images/activities/face_build.png',
  );

  static const social = ActivityDefinition(
    key: 'social',
    label: '社交小剧场',
    subtitle: '跟着故事练习社交表达',
    accentColor: Color(0xFFEF5350),
    assetPath: 'assets/images/activities/social.png',
  );

  static const diary = ActivityDefinition(
    key: 'diary',
    label: '心情日记',
    subtitle: '记录今天的小心情',
    accentColor: Color(0xFFFFCA28),
    assetPath: 'assets/images/activities/diary.png',
  );

  static const all = <ActivityDefinition>[
    detective,
    match,
    faceBuild,
    social,
    diary,
  ];

  static ActivityDefinition? byKey(String? key) {
    if (key == null) return null;
    for (final activity in all) {
      if (activity.key == key) return activity;
    }
    return null;
  }
}
