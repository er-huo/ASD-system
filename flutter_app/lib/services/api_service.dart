import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child.dart';
import '../models/question.dart';
import '../models/session.dart';

class ApiService {
  final String baseUrl;
  final http.Client httpClient;

  ApiService({required this.baseUrl, http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  Future<Child> createChild({required String name, int? age, String robotPreference = 'tino'}) async {
    final resp = await httpClient.post(
      Uri.parse('$baseUrl/children'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'age': age, 'robot_preference': robotPreference}),
    );
    if (resp.statusCode != 200) throw Exception('createChild failed: ${resp.body}');
    return Child.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<Child>> listChildren() async {
    final resp = await httpClient.get(Uri.parse('$baseUrl/children'));
    if (resp.statusCode != 200) throw Exception('listChildren failed');
    return (jsonDecode(resp.body) as List).map((e) => Child.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SessionStart> startSession({required String childId, required String activityType}) async {
    final resp = await httpClient.post(
      Uri.parse('$baseUrl/session/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'child_id': childId, 'activity_type': activityType}),
    );
    if (resp.statusCode != 200) throw Exception('startSession failed: ${resp.body}');
    return SessionStart.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<AnswerResult> submitAnswer({
    required String sessionId,
    required String emotionTarget,
    required String userResponse,
    required int responseMs,
    bool hintShown = false,
  }) async {
    final resp = await httpClient.post(
      Uri.parse('$baseUrl/session/answer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'emotion_target': emotionTarget,
        'user_response': userResponse,
        'response_ms': responseMs,
        'hint_shown': hintShown,
      }),
    );
    if (resp.statusCode != 200) throw Exception('submitAnswer failed: ${resp.body}');
    return AnswerResult.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> endSession(String sessionId) async {
    final resp = await httpClient.post(
      Uri.parse('$baseUrl/session/end'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId}),
    );
    if (resp.statusCode != 200) throw Exception('endSession failed');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReport(String childId) async {
    final resp = await httpClient.get(Uri.parse('$baseUrl/report/$childId'));
    if (resp.statusCode != 200) throw Exception('getReport failed');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
