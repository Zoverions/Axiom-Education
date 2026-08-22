import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/features/learning/home_learning_guide_screen.dart';

void main() {
  testWidgets('explains the home routine and course boundary', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeLearningGuideScreen()));

    expect(find.text('A 45-minute session'), findsOneWidget);
    expect(find.text('Two learners, one device'), findsOneWidget);
    expect(find.textContaining('not a complete MTH1W course'), findsOneWidget);
    expect(
      find.textContaining('three different practice questions'),
      findsOneWidget,
    );
    expect(find.text('Ready to try the routine?'), findsOneWidget);
    expect(find.text('Start mixed practice'), findsOneWidget);
  });
}
