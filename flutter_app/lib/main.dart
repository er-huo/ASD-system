import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/ip_config_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasBackendUrl = prefs.getString('backend_url') != null;
  runApp(ProviderScope(child: StarTalkApp(showIpConfig: !hasBackendUrl)));
}

class StarTalkApp extends StatelessWidget {
  final bool showIpConfig;
  const StarTalkApp({super.key, required this.showIpConfig});
  @override
  Widget build(BuildContext context) => _StarTalkRouter(showIpConfig: showIpConfig);
}

class _StarTalkRouter extends StatefulWidget {
  final bool showIpConfig;
  const _StarTalkRouter({required this.showIpConfig});
  @override
  State<_StarTalkRouter> createState() => _StarTalkRouterState();
}

class _StarTalkRouterState extends State<_StarTalkRouter> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.showIpConfig ? '/config' : '/splash',
    routes: [
      GoRoute(path: '/config',    builder: (_, __) => const IpConfigScreen()),
      GoRoute(path: '/splash',    builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/home',      builder: (_, s) => HomeScreen(childId: s.uri.queryParameters['child_id']!)),
      GoRoute(path: '/train',     builder: (_, s) => TrainingScreen(childId: s.uri.queryParameters['child_id']!, activityType: s.uri.queryParameters['activity']!)),
      GoRoute(path: '/summary',   builder: (_, s) => SummaryScreen(
        sessionId: s.uri.queryParameters['session_id']!,
        accuracy: int.tryParse(s.uri.queryParameters['accuracy'] ?? '0') ?? 0,
        total: int.tryParse(s.uri.queryParameters['total'] ?? '0') ?? 0,
      )),
      GoRoute(path: '/dashboard', builder: (_, s) => DashboardScreen(childId: s.uri.queryParameters['child_id']!)),
      GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: '星语灵境',
        theme: ThemeData(colorSchemeSeed: const Color(0xFFFFAA00), useMaterial3: true),
        routerConfig: _router,
      );
}
