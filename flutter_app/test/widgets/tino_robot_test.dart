import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startalk_asd/widgets/tino_robot.dart';

void main() {
  testWidgets('TinoRobot renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TinoRobot(emotion: 'happy', robotType: 'tino', size: 150))),
    );
    expect(find.byType(TinoRobot), findsOneWidget);
  });

  testWidgets('TinoRobot uses correct color for emotion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TinoRobot(emotion: 'angry', robotType: 'tino', size: 150))),
    );
    final container = tester.widget<Container>(find.byKey(const Key('tino_head')));
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color, const Color(0xFF7A1020));
  });
}
