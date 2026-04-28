import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

final backendUrlProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('backend_url') ?? 'http://192.168.1.100:8000';
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final asyncUrl = ref.watch(backendUrlProvider);
  final url = asyncUrl.valueOrNull ?? 'http://192.168.1.100:8000';
  return ApiService(baseUrl: url);
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final svc = WebSocketService();
  ref.onDispose(svc.dispose);
  return svc;
});
