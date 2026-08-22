import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_institution.dart';
import 'package:ontarioedai/widgets/guardian_learning_preferences.dart';

void main() {
  testWidgets(
    'guardian can request slower pacing without curriculum-removal UI',
    (tester) async {
      GuardianPacingPreference? pacing;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuardianLearningPreferencePanel(
              learningAreaLabel: 'Health and well-being',
              pacing: GuardianPacingPreference.noPreference,
              contentTiming: GuardianContentTimingPreference.noPreference,
              onPacingChanged: (value) => pacing = value,
              onContentTimingChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Slow down when allowed'), findsOneWidget);
      expect(
        find.textContaining('do not directly remove required learning'),
        findsOneWidget,
      );
      expect(find.text('Disable this curriculum'), findsNothing);

      await tester.tap(find.text('Slow down when allowed'));
      await tester.pump();

      expect(pacing, GuardianPacingPreference.slowDownWhenAllowed);
    },
  );

  testWidgets(
    'guardian can prioritize content timing when it becomes relevant',
    (tester) async {
      GuardianContentTimingPreference? timing;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuardianLearningPreferencePanel(
              learningAreaLabel: 'Digital citizenship',
              pacing: GuardianPacingPreference.maintain,
              contentTiming: GuardianContentTimingPreference.noPreference,
              onPacingChanged: (_) {},
              onContentTimingChanged: (value) => timing = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Prioritize when relevant'));
      await tester.pump();

      expect(timing, GuardianContentTimingPreference.prioritizeWhenRelevant);
    },
  );
}
