import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:startalk_asd/services/api_service.dart';

void main() {
  test('createChild returns Child on 200', () async {
    final client = MockClient((req) async {
      return http.Response(jsonEncode({
        'id': 'abc-123', 'name': '小明', 'age': 7,
        'robot_preference': 'tino', 'current_difficulty_level': 1,
        'created_at': '2026-04-27T10:00:00',
      }), 200, headers: {'content-type': 'application/json'});
    });
    final api = ApiService(baseUrl: 'http://localhost:8000', httpClient: client);
    final child = await api.createChild(name: '小明', age: 7, robotPreference: 'tino');
    expect(child.name, '小明');
    expect(child.id, 'abc-123');
  });

  test('createChild throws on non-200', () async {
    final client = MockClient((_) async => http.Response('error', 500));
    final api = ApiService(baseUrl: 'http://localhost:8000', httpClient: client);
    expect(() => api.createChild(name: '小明'), throwsException);
  });

  test('listChildren returns list of Child', () async {
    final client = MockClient((_) async => http.Response(jsonEncode([
      {'id': 'a', 'name': '小明', 'age': 7, 'robot_preference': 'tino', 'current_difficulty_level': 1, 'created_at': '2026-04-27T10:00:00'},
    ]), 200, headers: {'content-type': 'application/json'}));
    final api = ApiService(baseUrl: 'http://localhost:8000', httpClient: client);
    final children = await api.listChildren();
    expect(children.length, 1);
    expect(children.first.name, '小明');
  });
}
