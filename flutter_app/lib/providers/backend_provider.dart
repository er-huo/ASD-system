import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

final backendUrlProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('backend_url') ?? 'http://127.0.0.1:8000';
});

// Uses ref.read (not watch) so provider is NOT recreated when URL loads,
// preventing the in-flight request from being aborted.
final apiServiceProvider = Provider<ApiService>((ref) {
  // Read synchronously — falls back to 127.0.0.1 until prefs load,
  // then stays stable (no dispose/rebuild on FutureProvider resolve).
  final asyncUrl = ref.read(backendUrlProvider);
  final url = asyncUrl.valueOrNull ?? 'http://127.0.0.1:8000';
  return ApiService(baseUrl: url);
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final svc = WebSocketService();
  ref.onDispose(svc.dispose);
  return svc;
});
