import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:startalk_asd/main.dart';

void main() {
  testWidgets('StarTalkApp builds config route shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StarTalkApp(showIpConfig: true),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('连接后端服务器'), findsOneWidget);
    expect(find.text('后端 IP 地址'), findsOneWidget);
    expect(find.text('确认连接'), findsOneWidget);
  });
}
