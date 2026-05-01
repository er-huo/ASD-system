import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startalk_asd/config/activity_catalog.dart';
import 'package:startalk_asd/config/forest_theme.dart';
import 'package:startalk_asd/screens/home_screen.dart';
import 'package:startalk_asd/widgets/activity_card.dart';
import 'package:startalk_asd/widgets/activity_illustration.dart';

void main() {
  testWidgets('ActivityIllustration resolves detective asset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: const Scaffold(
          body: ActivityIllustration(activityKey: 'detective'),
        ),
      ),
    );

    expect(
      ActivityIllustration.assetPathFor('detective'),
      ActivityCatalog.detective.assetPath,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('ActivityCard shows configured label, subtitle and illustration',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: Scaffold(
          body: ActivityCard(
            activityKey: 'detective',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(ActivityCatalog.detective.label), findsOneWidget);
    expect(find.text(ActivityCatalog.detective.subtitle), findsOneWidget);
    expect(find.byType(ActivityIllustration), findsOneWidget);
  });

  testWidgets('ActivityCard remains tappable', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: Scaffold(
          body: ActivityCard(
            activityKey: 'match',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ActivityCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HomeScreen lays out activity cards responsively', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: const HomeScreen(childId: 'child-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCard), findsAtLeastNWidgets(1));
    expect(find.text(ActivityCatalog.detective.label), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(ActivityCatalog.diary.label),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(ActivityCatalog.diary.label), findsOneWidget);
    expect(tester.takeException(), isNull);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('ActivityCard keeps title group close to illustration panel',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forestTheme,
        home: Center(
          child: SizedBox(
            width: 420,
            child: ActivityCard(
              activityKey: 'detective',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final artBottom = tester.getBottomLeft(find.byType(ActivityIllustration)).dy;
    final titleTop = tester.getTopLeft(find.text(ActivityCatalog.detective.label)).dy;

    expect(titleTop - artBottom, lessThanOrEqualTo(48));
  });
}
