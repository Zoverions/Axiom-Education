import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/features/home/learner_home_screen.dart';

void main() {
  testWidgets('learner home opens the Claw Academy preview', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LearnerHomeScreen()),
    );

    final button = find.byKey(const ValueKey('home-open-claw-preview'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Claw Academy Preview'), findsOneWidget);
    expect(find.text('The bridge with four lanterns'), findsOneWidget);
    expect(
      find.textContaining('cannot change curriculum truth'),
      findsOneWidget,
    );
  });
}
