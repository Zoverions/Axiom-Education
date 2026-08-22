import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/learning_resource.dart';
import 'package:ontarioedai/widgets/learning_resource_feedback.dart';

void main() {
  testWidgets('primary feedback is explicit and learner controlled', (
    tester,
  ) async {
    LearningFeedbackSignal? signal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningResourceFeedbackPanel(
            onFeedback: (value) => signal = value,
          ),
        ),
      ),
    );

    expect(find.text('Did this help?'), findsOneWidget);
    expect(find.text('That helped'), findsOneWidget);
    expect(find.text('I still don’t get it'), findsOneWidget);
    expect(find.text('Show me another way'), findsOneWidget);
    expect(find.text('More like this'), findsOneWidget);

    await tester.tap(find.text('Show me another way'));
    await tester.pump();

    expect(signal, LearningFeedbackSignal.showAnotherWay);
  });

  testWidgets('fine grained feedback exposes pace and difficulty signals', (
    tester,
  ) async {
    final signals = <LearningFeedbackSignal>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningResourceFeedbackPanel(onFeedback: signals.add),
        ),
      ),
    );

    await tester.tap(find.text('Tell me more'));
    await tester.pumpAndSettle();

    expect(find.text('Too fast'), findsOneWidget);
    expect(find.text('Too slow'), findsOneWidget);
    expect(find.text('Too easy'), findsOneWidget);
    expect(find.text('Too hard'), findsOneWidget);
    expect(find.text('I already knew this'), findsOneWidget);

    await tester.tap(find.text('Too fast'));
    await tester.pump();
    expect(signals.last, LearningFeedbackSignal.tooFast);
  });

  testWidgets('compact feedback hides the fine grained expansion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningResourceFeedbackPanel(
            onFeedback: (_) {},
            showFineGrainedFeedback: false,
          ),
        ),
      ),
    );

    expect(find.text('Tell me more'), findsNothing);
    expect(find.text('That helped'), findsOneWidget);
  });
}
