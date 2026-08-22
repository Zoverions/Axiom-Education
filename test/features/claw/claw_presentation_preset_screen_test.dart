import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/features/claw/claw_foundations_preview_screen.dart';
import 'package:ontarioedai/features/claw/claw_foundations_story_arc.dart';

void main() {
  testWidgets(
    'presentation preset changes wording without resetting graph position',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ClawFoundationsPreviewScreen()),
      );

      expect(find.text('The bridge with four lanterns'), findsOneWidget);
      expect(find.textContaining('Explorer: Balanced story'), findsOneWidget);
      expect(
        find.text('Learning target: ${ClawFoundationsStoryArc.competencyId}'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('claw-preset-sprout')));
      await tester.pumpAndSettle();

      expect(find.text('The four-lantern bridge'), findsOneWidget);
      expect(find.textContaining('Sprout: Light reading load'), findsOneWidget);
      expect(
        find.text('Learning target: ${ClawFoundationsStoryArc.competencyId}'),
        findsOneWidget,
      );

      final continueButton = find.byKey(const ValueKey('claw-continue'));
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Make the same amount'), findsOneWidget);

      final scholarChip = find.byKey(const ValueKey('claw-preset-scholar'));
      await tester.ensureVisible(scholarChip);
      await tester.pumpAndSettle();
      await tester.tap(scholarChip);
      await tester.pumpAndSettle();

      expect(find.text('Make the same amount'), findsNothing);
      expect(find.text('One half can wear another name'), findsOneWidget);
      expect(find.textContaining('form of 1'), findsOneWidget);
      expect(find.textContaining('Scholar: Explicit concepts'), findsOneWidget);
      expect(find.text('The bridge with four lanterns'), findsNothing);
      expect(
        find.text('Learning target: ${ClawFoundationsStoryArc.competencyId}'),
        findsOneWidget,
      );
    },
  );
}
