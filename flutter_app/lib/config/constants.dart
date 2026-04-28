import 'package:flutter/material.dart';

const String kTherapistPassword = 'admin1234';

const List<String> kEmotions = [
  'happy', 'sad', 'angry', 'fear', 'surprise', 'neutral', 'confused',
];

const Map<String, Color> kEmotionColors = {
  'happy':    Color(0xFFFFAA00),
  'angry':    Color(0xFF7A1020),
  'sad':      Color(0xFF1A3A9A),
  'fear':     Color(0xFF5A2880),
  'neutral':  Color(0xFF557799),
  'confused': Color(0xFFCC7733),
  'surprise': Color(0xFFDDCC10),
};

const Map<String, String> kEmotionAudio = {
  'happy':    'assets/audio/happy.mp3',
  'sad':      'assets/audio/sad.mp3',
  'angry':    'assets/audio/angry.mp3',
  'fear':     'assets/audio/fear.mp3',
  'neutral':  'assets/audio/neutral.mp3',
  'surprise': 'assets/audio/surprise.mp3',
  'confused': 'assets/audio/confused.mp3',
};

const Map<String, String> kEmotionAnimations = {
  'happy':    'wave',
  'sad':      'droop',
  'angry':    'slam',
  'fear':     'raise',
  'neutral':  'float',
  'confused': 'tilt',
  'surprise': 'jump',
};

const int kQuestionsPerSession = 10;

const Map<String, String> kActivityLabels = {
  'detective':  '情绪大侦探',
  'match':      '表情连连看',
  'face_build': '拼脸大师',
  'social':     '社交小剧场',
  'diary':      '心情日记',
};
