import 'dart:math';

enum ReviewRating { again, hard, good, easy }

class ReviewSchedulerState {
  const ReviewSchedulerState({
    this.version = currentVersion,
    this.stabilityDays = 1.0,
    this.difficulty = 5.0,
    this.repetitions = 0,
    this.lapses = 0,
  });

  static const int currentVersion = 1;

  final int version;
  final double stabilityDays;
  final double difficulty;
  final int repetitions;
  final int lapses;

  bool get isValid =>
      version == currentVersion &&
      stabilityDays.isFinite &&
      stabilityDays >= ReviewScheduler.minStabilityDays &&
      stabilityDays <= ReviewScheduler.maxStabilityDays &&
      difficulty.isFinite &&
      difficulty >= ReviewScheduler.minDifficulty &&
      difficulty <= ReviewScheduler.maxDifficulty &&
      repetitions >= 0 &&
      lapses >= 0;
}

class ReviewScheduleResult {
  const ReviewScheduleResult({
    required this.interval,
    required this.state,
    this.usedFallback = false,
  });

  final Duration interval;
  final ReviewSchedulerState state;
  final bool usedFallback;
}

class ReviewStateLoadResult {
  const ReviewStateLoadResult({
    required this.state,
    required this.usedFallback,
    required this.migrated,
  });

  final ReviewSchedulerState state;
  final bool usedFallback;
  final bool migrated;
}

/// Pure, deterministic review scheduling state.
///
/// This is intentionally local and side-effect free. It does not read or write
/// learner records, decide answer correctness, perform network calls, or grant
/// any authority. The current formula is an AXIOM-native bounded scheduling
/// contract inspired by spaced-repetition practice; it is not an FSRS
/// compatibility claim.
class ReviewScheduler {
  static const Duration conservativeInterval = Duration(days: 1);
  static const double minStabilityDays = 0.25;
  static const double maxStabilityDays = 3650.0;
  static const double minDifficulty = 1.0;
  static const double maxDifficulty = 10.0;

  static ReviewScheduleResult schedule({
    required ReviewSchedulerState state,
    required ReviewRating rating,
  }) {
    if (!state.isValid) {
      return const ReviewScheduleResult(
        interval: conservativeInterval,
        state: ReviewSchedulerState(),
        usedFallback: true,
      );
    }

    var stability = state.stabilityDays;
    var difficulty = state.difficulty;
    var lapses = state.lapses;

    switch (rating) {
      case ReviewRating.again:
        stability = max(minStabilityDays, min(1.0, stability * 0.35));
        difficulty += 0.8;
        lapses += 1;
      case ReviewRating.hard:
        stability *= 1.2;
        difficulty += 0.2;
      case ReviewRating.good:
        stability *= 2.5;
        difficulty -= 0.15;
      case ReviewRating.easy:
        stability *= 4.0;
        difficulty -= 0.4;
    }

    stability = stability.clamp(minStabilityDays, maxStabilityDays).toDouble();
    difficulty = difficulty.clamp(minDifficulty, maxDifficulty).toDouble();
    final intervalDays = stability.round().clamp(1, maxStabilityDays.toInt());

    return ReviewScheduleResult(
      interval: Duration(days: intervalDays),
      state: ReviewSchedulerState(
        stabilityDays: stability,
        difficulty: difficulty,
        repetitions: state.repetitions + 1,
        lapses: lapses,
      ),
    );
  }

  /// Loads a versioned state object without performing persistence.
  ///
  /// Version 0 is a legacy synthetic fixture format used only to exercise the
  /// migration contract. Migrated numeric parameters are clipped to current
  /// safe bounds. Malformed or unsupported state fails closed to the default
  /// state and a one-day review interval when subsequently scheduled.
  static ReviewStateLoadResult loadVersionedState(Map<String, Object?> raw) {
    final version = _readInt(raw['version']);
    if (version == null) return _fallbackLoad();

    if (version == ReviewSchedulerState.currentVersion) {
      final state = _readCurrentState(raw);
      if (state == null || !state.isValid) return _fallbackLoad();
      return ReviewStateLoadResult(
        state: state,
        usedFallback: false,
        migrated: false,
      );
    }

    if (version == 0) {
      final stability = _readDouble(raw['stabilityDays']);
      final difficulty = _readDouble(raw['difficulty']);
      final repetitions = _readInt(raw['repetitions']);
      final lapses = _readInt(raw['lapses']);
      if (stability == null ||
          difficulty == null ||
          repetitions == null ||
          lapses == null ||
          !stability.isFinite ||
          !difficulty.isFinite) {
        return _fallbackLoad();
      }

      return ReviewStateLoadResult(
        state: ReviewSchedulerState(
          stabilityDays:
              stability.clamp(minStabilityDays, maxStabilityDays).toDouble(),
          difficulty: difficulty.clamp(minDifficulty, maxDifficulty).toDouble(),
          repetitions: max(0, repetitions),
          lapses: max(0, lapses),
        ),
        usedFallback: false,
        migrated: true,
      );
    }

    return _fallbackLoad();
  }

  static ReviewSchedulerState? _readCurrentState(Map<String, Object?> raw) {
    final stability = _readDouble(raw['stabilityDays']);
    final difficulty = _readDouble(raw['difficulty']);
    final repetitions = _readInt(raw['repetitions']);
    final lapses = _readInt(raw['lapses']);
    if (stability == null ||
        difficulty == null ||
        repetitions == null ||
        lapses == null) {
      return null;
    }

    return ReviewSchedulerState(
      stabilityDays: stability,
      difficulty: difficulty,
      repetitions: repetitions,
      lapses: lapses,
    );
  }

  static ReviewStateLoadResult _fallbackLoad() => const ReviewStateLoadResult(
        state: ReviewSchedulerState(),
        usedFallback: true,
        migrated: false,
      );

  static double? _readDouble(Object? value) => value is num ? value.toDouble() : null;

  static int? _readInt(Object? value) => value is int ? value : null;
}
