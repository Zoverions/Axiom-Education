import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/fsrs_day_scheduler.dart';

void main() {
  group('FsrsDayScheduler upstream reference vectors', () {
    test('matches pinned FSRS-6 forgetting-curve values', () {
      expect(FsrsDayScheduler.forgettingCurve(0, 1.0), 1.0);
      expect(FsrsDayScheduler.forgettingCurve(1, 1.0), 0.9);
      expect(FsrsDayScheduler.forgettingCurve(2, 1.0), 0.84588465);
      expect(FsrsDayScheduler.forgettingCurve(3, 1.0), 0.8093881);
    });

    test('matches pinned next-difficulty values', () {
      final actual = <double>[
        for (final rating in ReviewRating.values)
          FsrsDayScheduler.nextDifficulty(5.0, rating.grade),
      ];

      const expected = <double>[8.34176237, 6.66599536, 4.99022837, 3.31446137];

      for (var index = 0; index < expected.length; index++) {
        expect(actual[index], closeTo(expected[index], 1e-8));
      }
    });

    test('matches pinned recall-stability values', () {
      const difficulties = <double>[1.0, 2.0, 3.0, 4.0];
      const retrievabilities = <double>[0.9, 0.8, 0.7, 0.6];
      const expected = <double>[
        25.60252118,
        28.22657096,
        58.65599107,
        127.2266925,
      ];

      for (var index = 0; index < ReviewRating.values.length; index++) {
        final actual = FsrsDayScheduler.nextRecallStability(
          difficulties[index],
          5.0,
          retrievabilities[index],
          ReviewRating.values[index].grade,
        );
        expect(actual, closeTo(expected[index], 1e-8));
      }
    });

    test('matches pinned forgetting-stability values', () {
      const difficulties = <double>[1.0, 2.0, 3.0, 4.0];
      const retrievabilities = <double>[0.9, 0.8, 0.7, 0.6];
      const expected = <double>[1.05253961, 1.18943295, 1.36808387, 1.58498896];

      for (var index = 0; index < expected.length; index++) {
        final actual = FsrsDayScheduler.nextForgetStability(
          difficulties[index],
          5.0,
          retrievabilities[index],
        );
        expect(actual, closeTo(expected[index], 1e-8));
      }
    });

    test('matches pinned short-term stability values', () {
      const expected = <double>[1.596818, 5.0, 5.0, 8.12960956];

      for (var index = 0; index < ReviewRating.values.length; index++) {
        final actual = FsrsDayScheduler.nextShortTermStability(
          5.0,
          ReviewRating.values[index].grade,
        );
        expect(actual, closeTo(expected[index], 1e-8));
      }
    });
  });

  group('FsrsDayScheduler scheduling boundary', () {
    test('is deterministic for identical explicit inputs', () {
      const state = ReviewMemoryState(
        schemaVersion: ReviewMemoryState.currentSchemaVersion,
        stabilityDays: 5.0,
        difficulty: 5.0,
        repetitions: 4,
        lapses: 1,
      );

      final first = FsrsDayScheduler.schedule(
        rating: ReviewRating.good,
        elapsedDays: 3,
        currentState: state,
      );
      final second = FsrsDayScheduler.schedule(
        rating: ReviewRating.good,
        elapsedDays: 3,
        currentState: state,
      );

      expect(first.usedConservativeFallback, isFalse);
      expect(second.usedConservativeFallback, isFalse);
      expect(first.interval, second.interval);
      expect(first.nextState!.schemaVersion, second.nextState!.schemaVersion);
      expect(first.nextState!.stabilityDays, second.nextState!.stabilityDays);
      expect(first.nextState!.difficulty, second.nextState!.difficulty);
      expect(first.nextState!.repetitions, second.nextState!.repetitions);
      expect(first.nextState!.lapses, second.nextState!.lapses);
    });

    test(
      'creates a bounded first state without touching correctness authority',
      () {
        final result = FsrsDayScheduler.schedule(
          rating: ReviewRating.good,
          elapsedDays: 0,
        );

        expect(result.usedConservativeFallback, isFalse);
        expect(result.interval, const Duration(days: 2));
        expect(result.nextState, isNotNull);
        expect(
          result.nextState!.schemaVersion,
          ReviewMemoryState.currentSchemaVersion,
        );
        expect(result.nextState!.stabilityDays, closeTo(2.3065, 1e-8));
        expect(result.nextState!.difficulty, closeTo(2.11810397, 1e-8));
        expect(result.nextState!.repetitions, 1);
        expect(result.nextState!.lapses, 0);
      },
    );

    test('counts a lapse only after an existing state forgets', () {
      const state = ReviewMemoryState(
        schemaVersion: ReviewMemoryState.currentSchemaVersion,
        stabilityDays: 5.0,
        difficulty: 5.0,
        repetitions: 2,
        lapses: 1,
      );

      final result = FsrsDayScheduler.schedule(
        rating: ReviewRating.again,
        elapsedDays: 7,
        currentState: state,
      );

      expect(result.usedConservativeFallback, isFalse);
      expect(result.nextState!.repetitions, 3);
      expect(result.nextState!.lapses, 2);
      expect(result.interval.inDays, greaterThanOrEqualTo(1));
    });

    test('fails closed on unsupported state version', () {
      const state = ReviewMemoryState(
        schemaVersion: 99,
        stabilityDays: 5.0,
        difficulty: 5.0,
        repetitions: 1,
        lapses: 0,
      );

      final result = FsrsDayScheduler.schedule(
        rating: ReviewRating.easy,
        elapsedDays: 5,
        currentState: state,
      );

      expect(result.usedConservativeFallback, isTrue);
      expect(result.interval, FsrsDayScheduler.conservativeInterval);
      expect(result.nextState, isNull);
      expect(result.fallbackReason, 'unsupported scheduler state version');
    });

    test('fails closed on malformed state instead of widening interval', () {
      const state = ReviewMemoryState(
        schemaVersion: ReviewMemoryState.currentSchemaVersion,
        stabilityDays: double.nan,
        difficulty: 5.0,
        repetitions: 1,
        lapses: 0,
      );

      final result = FsrsDayScheduler.schedule(
        rating: ReviewRating.easy,
        elapsedDays: 5,
        currentState: state,
      );

      expect(result.usedConservativeFallback, isTrue);
      expect(result.interval, const Duration(days: 1));
      expect(result.nextState, isNull);
    });

    test('fails closed on negative elapsed time', () {
      final result = FsrsDayScheduler.schedule(
        rating: ReviewRating.good,
        elapsedDays: -1,
      );

      expect(result.usedConservativeFallback, isTrue);
      expect(result.interval, const Duration(days: 1));
      expect(result.nextState, isNull);
    });
  });
}
