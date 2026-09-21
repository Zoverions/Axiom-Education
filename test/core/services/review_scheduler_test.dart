import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';
import 'package:ontarioedai/core/services/review_scheduler.dart';

void main() {
  group('ReviewScheduler', () {
    test('is deterministic for identical state and rating', () {
      const state = ReviewSchedulerState(
        stabilityDays: 2.0,
        difficulty: 5.0,
        repetitions: 3,
        lapses: 1,
      );

      final first = ReviewScheduler.schedule(
        state: state,
        rating: ReviewRating.good,
      );
      final second = ReviewScheduler.schedule(
        state: state,
        rating: ReviewRating.good,
      );

      expect(first.interval, second.interval);
      expect(first.state.stabilityDays, second.state.stabilityDays);
      expect(first.state.difficulty, second.state.difficulty);
      expect(first.state.repetitions, second.state.repetitions);
      expect(first.state.lapses, second.state.lapses);
      expect(first.usedFallback, isFalse);
    });

    test('matches the bounded AXIOM v1 reference fixtures', () {
      const state = ReviewSchedulerState(stabilityDays: 2.0, difficulty: 5.0);

      final fixtures = <ReviewRating, (int, double, double, int)>{
        ReviewRating.again: (1, 0.7, 5.8, 1),
        ReviewRating.hard: (2, 2.4, 5.2, 0),
        ReviewRating.good: (5, 5.0, 4.85, 0),
        ReviewRating.easy: (8, 8.0, 4.6, 0),
      };

      for (final entry in fixtures.entries) {
        final result = ReviewScheduler.schedule(
          state: state,
          rating: entry.key,
        );
        final expected = entry.value;
        expect(result.interval, Duration(days: expected.$1));
        expect(result.state.stabilityDays, closeTo(expected.$2, 1e-12));
        expect(result.state.difficulty, closeTo(expected.$3, 1e-12));
        expect(result.state.lapses, expected.$4);
        expect(result.state.repetitions, 1);
      }
    });

    test('clips migrated legacy parameters to safe lower bounds', () {
      final loaded = ReviewScheduler.loadVersionedState({
        'version': 0,
        'stabilityDays': 100000.0,
        'difficulty': -20.0,
        'repetitions': -4,
        'lapses': -2,
      });

      expect(loaded.usedFallback, isFalse);
      expect(loaded.migrated, isTrue);
      expect(loaded.state.version, ReviewSchedulerState.currentVersion);
      expect(loaded.state.stabilityDays, ReviewScheduler.maxStabilityDays);
      expect(loaded.state.difficulty, ReviewScheduler.minDifficulty);
      expect(loaded.state.repetitions, 0);
      expect(loaded.state.lapses, 0);
    });

    test('clips migrated legacy counters to a portable upper bound', () {
      final loaded = ReviewScheduler.loadVersionedState({
        'version': 0,
        'stabilityDays': 1.0,
        'difficulty': 5.0,
        'repetitions': ReviewScheduler.maxReviewCount + 100,
        'lapses': ReviewScheduler.maxReviewCount + 200,
      });

      expect(loaded.usedFallback, isFalse);
      expect(loaded.migrated, isTrue);
      expect(loaded.state.repetitions, ReviewScheduler.maxReviewCount);
      expect(loaded.state.lapses, ReviewScheduler.maxReviewCount);
    });

    test('current state above the counter bound fails closed', () {
      final result = ReviewScheduler.scheduleVersionedState(
        rawState: {
          'version': ReviewSchedulerState.currentVersion,
          'stabilityDays': 2.0,
          'difficulty': 5.0,
          'repetitions': ReviewScheduler.maxReviewCount + 1,
          'lapses': 0,
        },
        rating: ReviewRating.easy,
      );

      expect(result.usedFallback, isTrue);
      expect(result.interval, ReviewScheduler.conservativeInterval);
    });

    test('valid counters saturate at the supported upper bound', () {
      const state = ReviewSchedulerState(
        stabilityDays: 2.0,
        difficulty: 5.0,
        repetitions: ReviewScheduler.maxReviewCount,
        lapses: ReviewScheduler.maxReviewCount,
      );

      final result = ReviewScheduler.schedule(
        state: state,
        rating: ReviewRating.again,
      );

      expect(result.usedFallback, isFalse);
      expect(result.state.repetitions, ReviewScheduler.maxReviewCount);
      expect(result.state.lapses, ReviewScheduler.maxReviewCount);
      expect(result.state.isValid, isTrue);
    });

    test('malformed state fails closed to a one-day review', () {
      final result = ReviewScheduler.scheduleVersionedState(
        rawState: {
          'version': 1,
          'stabilityDays': 'not-a-number',
          'difficulty': 5.0,
          'repetitions': 1,
          'lapses': 0,
        },
        rating: ReviewRating.easy,
      );

      expect(result.usedFallback, isTrue);
      expect(result.interval, ReviewScheduler.conservativeInterval);
      expect(result.state, isA<ReviewSchedulerState>());
    });

    test(
      'unsupported future state fails closed rather than widening interval',
      () {
        final result = ReviewScheduler.scheduleVersionedState(
          rawState: {
            'version': 99,
            'stabilityDays': 1000.0,
            'difficulty': 1.0,
            'repetitions': 100,
            'lapses': 0,
          },
          rating: ReviewRating.easy,
        );

        expect(result.usedFallback, isTrue);
        expect(result.interval, const Duration(days: 1));
      },
    );

    test('adaptive engine delegates to the pure scheduler boundary', () {
      const state = ReviewSchedulerState(stabilityDays: 2.0, difficulty: 5.0);

      final result = AdaptiveEngine.scheduleReview(
        state: state,
        rating: ReviewRating.good,
      );

      expect(result.interval, const Duration(days: 5));
      expect(result.state.repetitions, 1);
    });
  });
}
