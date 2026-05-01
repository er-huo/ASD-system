import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startalk_asd/config/forest_theme.dart';
import 'package:startalk_asd/models/child.dart';
import 'package:startalk_asd/models/question.dart';
import 'package:startalk_asd/models/session.dart';
import 'package:startalk_asd/providers/backend_provider.dart';
import 'package:startalk_asd/screens/home_screen.dart';
import 'package:startalk_asd/screens/splash_screen.dart';
import 'package:startalk_asd/screens/summary_screen.dart';
import 'package:startalk_asd/screens/training_screen.dart';
import 'package:startalk_asd/services/api_service.dart';
import 'package:startalk_asd/widgets/activity_card.dart';
import 'package:startalk_asd/widgets/decorated_card.dart';
import 'package:startalk_asd/widgets/page_background.dart';
import 'package:startalk_asd/widgets/section_title.dart';
import 'package:startalk_asd/widgets/soft_status_badge.dart';
import 'package:startalk_asd/widgets/tino_robot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'default_difficulty': 1});
  });

  testWidgets('forestTheme MaterialApp builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: const Scaffold(
          body: Text('Themed app'),
        ),
      ),
    );

    expect(find.text('Themed app'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
        same(forestTheme));
  });

  testWidgets('PageBackground renders decorative asset slots when provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: const Scaffold(
          body: PageBackground(
            topDecorativeAssetPath: 'assets/images/ui/top_decor.png',
            bottomDecorativeAssetPath: 'assets/images/ui/bottom_decor.png',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ui/top_decor.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ui/bottom_decor.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PageBackground + DecoratedCard + SectionTitle render together',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: Scaffold(
          body: PageBackground(
            child: Center(
              child: DecoratedCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SectionTitle(title: 'Mood Garden'),
                    SizedBox(height: 8),
                    Text('Gentle and calm interface'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageBackground), findsOneWidget);
    expect(find.byType(DecoratedCard), findsOneWidget);
    expect(find.byType(SectionTitle), findsOneWidget);
    expect(find.text('Mood Garden'), findsOneWidget);
    expect(find.text('Gentle and calm interface'), findsOneWidget);
  });

  testWidgets('SoftStatusBadge renders icon and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: const Scaffold(
          body: SoftStatusBadge(
            label: '摄像头识别中',
            icon: Icons.videocam_outlined,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('soft_status_badge_wrap')), findsOneWidget);
    expect(find.byKey(const Key('soft_status_badge_icon')), findsOneWidget);
    expect(find.byKey(const Key('soft_status_badge_label')), findsOneWidget);
    expect(find.text('摄像头识别中'), findsOneWidget);
  });

  testWidgets('SplashScreen uses forest shell and shows profile/story sections',
      (tester) async {
    await tester.pumpWidget(_buildApp(const SplashScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(PageBackground), findsOneWidget);
    expect(find.byKey(const Key('splash_hero_image')), findsOneWidget);
    expect(find.text('选择你的伙伴'), findsOneWidget);
    expect(find.text('Tino（男）'), findsOneWidget);
    expect(find.text('Tina（女）'), findsOneWidget);
    expect(find.text('已有档案'), findsOneWidget);
    expect(find.text('小满'), findsOneWidget);
  });

  testWidgets('HomeScreen keeps forest framing and activity grid',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildApp(const HomeScreen(childId: 'child-1')));
    await tester.pumpAndSettle();

    expect(find.byType(PageBackground), findsOneWidget);
    expect(find.text('今天想先玩什么？'), findsOneWidget);
    expect(find.text('治疗师入口'), findsOneWidget);
    expect(find.byType(ActivityCard), findsAtLeastNWidgets(2));
    expect(find.text('情绪大侦探'), findsOneWidget);
  });

  testWidgets('TrainingScreen uses companion split layout and content card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildApp(
          const TrainingScreen(childId: 'child-1', activityType: 'detective')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PageBackground), findsOneWidget);
    expect(find.textContaining('准备'), findsNothing);
    expect(find.textContaining('错误:'), findsNothing);
    expect(find.byType(TinoRobot), findsOneWidget);
    expect(find.text('摄像头识别中'), findsOneWidget);
    expect(find.text('轻轻选一个答案'), findsOneWidget);
  });

  testWidgets('SummaryScreen groups finish report into decorated cards',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const SummaryScreen(sessionId: 'session-1', accuracy: 80, total: 10),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PageBackground), findsOneWidget);
    expect(find.byKey(const Key('summary_finish_art')), findsOneWidget);
    expect(find.text('今天的训练完成啦'), findsOneWidget);
    expect(find.text('情绪变化曲线'), findsOneWidget);
    expect(find.text('本次主要情绪'), findsOneWidget);
    expect(find.text('回到主页'), findsOneWidget);
  });
}

Widget _buildApp(Widget child) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(_FakeApiService()),
      backendUrlProvider.overrideWith((ref) async => 'http://127.0.0.1:8000'),
    ],
    child: MaterialApp(
      theme: forestTheme,
      home: child,
    ),
  );
}

class _FakeApiService extends ApiService {
  _FakeApiService() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<List<Child>> listChildren() async {
    return const [
      Child(
        id: 'child-1',
        name: '小满',
        robotPreference: 'tino',
        currentDifficultyLevel: 2,
      ),
    ];
  }

  @override
  Future<SessionStart> startSession({
    required String childId,
    required String activityType,
  }) async {
    return SessionStart(
      sessionId: 'session-1',
      difficulty: 1,
      firstQuestion: Question(
        id: 'q1',
        activityType: activityType,
        emotionTarget: 'happy',
        difficultyLevel: 2,
        stimuliType: 'asset',
        stimuliPath: 'assets/images/activities/detective.png',
        choices: const ['happy', 'sad', 'angry'],
        correctAnswer: 'happy',
        questionText: 'Tino现在是什么心情？',
        scenario: '小明收到了礼物。',
        elements: const ['eyes', 'mouth'],
      ),
    );
  }

  @override
  Future<dynamic> get(String path) async {
    return [
      {'emotion': 'happy'},
      {'emotion': 'happy'},
      {'emotion': 'neutral'},
      {'emotion': 'surprise'},
    ];
  }
}
