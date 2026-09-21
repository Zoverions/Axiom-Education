import 'dart:math' as math;

/// Learner self-rating used only for review scheduling.
///
/// This rating is not answer correctness and grants no authority.
enum ReviewRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const ReviewRating(this.grade);

  final int grade;
}

/// Pure in-memory scheduling state.
///
/// This type intentionally has no persistence, network, credential, device, or
/// provider behavior. `schemaVersion` makes incompatible state explicit so a
/// caller cannot silently reinterpret future scheduler state.
class ReviewMemoryState {
  const ReviewMemoryState({
    required this.schemaVersion,
    required this.stabilityDays,
    required this.difficulty,
    required this.repetitions,
    required this.lapses,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final double stabilityDays;
  final double difficulty;
  final int repetitions;
  final int lapses;
}

/// Result of one pure scheduling step.
///
/// When [usedConservativeFallback] is true, [nextState] is intentionally null:
/// callers may surface the one-day review interval, but must not persist a
/// fabricated or silently migrated state.
class ReviewScheduleResult {
  const ReviewScheduleResult({
    required this.interval,
    required this.nextState,
    required this.usedConservativeFallback,
    this.fallbackReason,
  });

  final Duration interval;
  final ReviewMemoryState? nextState;
  final bool usedConservativeFallback;
  final String? fallbackReason;
}

/// A pure, deterministic, day-granularity FSRS-6 scheduling candidate.
///
/// The formulas and default parameter vector are adapted from ts-fsrs v5.4.2
/// at commit bb71e35a2f5af5a5ac6cce9ef7c41ad24855721d (MIT). See
/// THIRD_PARTY_NOTICES.md. This is deliberately not a full ts-fsrs port: it
/// does not implement learning/relearning step queues, fuzzing, persistence,
/// UI integration, provider calls, or learner-record mutation.
///
/// Scheduling remains advisory. It does not determine answer correctness and
/// does not interact with MathAnswerVerifier or any other correctness authority.
class FsrsDayScheduler {
  static const Duration conservativeInterval = Duration(days: 1);
  static const int maximumIntervalDays = 36500;
  static const double requestedRetention = 0.9;

  static const double _stabilityMin = 0.001;
  static const double _stabilityMax = 36500.0;

  // ts-fsrs v5.4.2 / FSRS-6 default parameter vector.
  static const List<double> _weights = <double>[
    0.212,
    1.2931,
    2.3065,
    8.2956,
    6.4133,
    0.8334,
    3.0194,
    0.001,
    1.8722,
    0.1666,
    0.796,
    1.4835,
    0.0614,
    0.2629,
    1.6483,
    0.6014,
    1.8729,
    0.5425,
    0.0912,
    0.0658,
    0.1542,
  ];

  /// Advances review state without any side effects.
  ///
  /// Invalid elapsed time or incompatible/malformed state fails closed to a
  /// one-day review interval and produces no state that could be persisted.
  static ReviewScheduleResult schedule({
    required ReviewRating rating,
    required int elapsedDays,
    ReviewMemoryState? currentState,
  }) {
    if (elapsedDays < 0) {
      return _fallback('elapsedDays must be non-negative');
    }
    if (currentState == null && elapsedDays != 0) {
      return _fallback('elapsedDays must be zero without prior state');
    }

    if (currentState != null) {
      final invalidReason = _stateInvalidReason(currentState);
      if (invalidReason != null) {
        return _fallback(invalidReason);
      }
    }

    final int grade = rating.grade;
    late final double nextDifficultyValue;
    late final double nextStabilityValue;

    if (currentState == null) {
      nextDifficultyValue = _clampDouble(initDifficulty(grade), 1.0, 10.0);
      nextStabilityValue = initStability(grade);
    } else {
      final d = currentState.difficulty;
      final s = currentState.stabilityDays;
      final retrievability = forgettingCurve(elapsedDays, s);

      if (elapsedDays == 0) {
        nextStabilityValue = nextShortTermStability(s, grade);
      } else if (grade == ReviewRating.again.grade) {
        final stabilityAfterFail = nextForgetStability(d, s, retrievability);
        final nextStabilityMin = s / math.exp(_weights[17] * _weights[18]);
        nextStabilityValue = _clampDouble(
          _round8(nextStabilityMin),
          _stabilityMin,
          stabilityAfterFail,
        );
      } else {
        nextStabilityValue = nextRecallStability(d, s, retrievability, grade);
      }

      nextDifficultyValue = nextDifficulty(d, grade);
    }

    final previousRepetitions = currentState?.repetitions ?? 0;
    final previousLapses = currentState?.lapses ?? 0;
    final isLapse = currentState != null && rating == ReviewRating.again;

    final nextState = ReviewMemoryState(
      schemaVersion: ReviewMemoryState.currentSchemaVersion,
      stabilityDays: nextStabilityValue,
      difficulty: nextDifficultyValue,
      repetitions: previousRepetitions + 1,
      lapses: previousLapses + (isLapse ? 1 : 0),
    );

    return ReviewScheduleResult(
      interval: Duration(days: nextInterval(nextState.stabilityDays)),
      nextState: nextState,
      usedConservativeFallback: false,
    );
  }

  /// FSRS forgetting curve. Public for reference-vector regression tests.
  static double forgettingCurve(int elapsedDays, double stabilityDays) {
    if (elapsedDays < 0) {
      throw ArgumentError.value(
        elapsedDays,
        'elapsedDays',
        'must be non-negative',
      );
    }
    if (!stabilityDays.isFinite || stabilityDays <= 0) {
      throw ArgumentError.value(
        stabilityDays,
        'stabilityDays',
        'must be finite and greater than zero',
      );
    }

    final decay = -_weights[20];
    final factor = _round8(math.exp(math.log(0.9) / decay) - 1.0);
    final base = 1.0 + (factor * elapsedDays) / stabilityDays;
    return _round8(math.pow(base, decay).toDouble());
  }

  /// Initial stability for a grade, matching the pinned FSRS-6 defaults.
  static double initStability(int grade) {
    return math.max(_weights[grade - 1], 0.1);
  }

  /// Raw initial difficulty before the scheduling-state [1, 10] clamp.
  static double initDifficulty(int grade) {
    return _round8(_weights[4] - math.exp((grade - 1) * _weights[5]) + 1.0);
  }

  /// Difficulty update for an existing valid scheduling state.
  static double nextDifficulty(double difficulty, int grade) {
    final deltaDifficulty = -_weights[6] * (grade - 3);
    final dampedDelta = _round8((deltaDifficulty * (10.0 - difficulty)) / 9.0);
    final next = difficulty + dampedDelta;
    final reverted = _round8(
      _weights[7] * initDifficulty(ReviewRating.easy.grade) +
          (1.0 - _weights[7]) * next,
    );
    return _clampDouble(reverted, 1.0, 10.0);
  }

  /// Recall stability update for an existing valid scheduling state.
  static double nextRecallStability(
    double difficulty,
    double stabilityDays,
    double retrievability,
    int grade,
  ) {
    final hardPenalty = grade == ReviewRating.hard.grade ? _weights[15] : 1.0;
    final easyBonus = grade == ReviewRating.easy.grade ? _weights[16] : 1.0;
    final stabilityPower = math.pow(stabilityDays, -_weights[9]).toDouble();
    final recallGrowth =
        math.exp(_weights[8]) *
        (11.0 - difficulty) *
        stabilityPower *
        (math.exp((1.0 - retrievability) * _weights[10]) - 1.0) *
        hardPenalty *
        easyBonus;

    return _round8(
      _clampDouble(
        stabilityDays * (1.0 + recallGrowth),
        _stabilityMin,
        _stabilityMax,
      ),
    );
  }

  /// Forgetting stability update for an existing valid scheduling state.
  static double nextForgetStability(
    double difficulty,
    double stabilityDays,
    double retrievability,
  ) {
    final next =
        _weights[11] *
        math.pow(difficulty, -_weights[12]).toDouble() *
        (math.pow(stabilityDays + 1.0, _weights[13]).toDouble() - 1.0) *
        math.exp((1.0 - retrievability) * _weights[14]);
    return _round8(_clampDouble(next, _stabilityMin, _stabilityMax));
  }

  /// Short-term stability update used when no whole day has elapsed.
  static double nextShortTermStability(double stabilityDays, int grade) {
    final stabilityIncrement =
        math.pow(stabilityDays, -_weights[19]).toDouble() *
        math.exp(_weights[17] * (grade - 3 + _weights[18]));
    final maskedIncrement = grade >= ReviewRating.hard.grade
        ? math.max(stabilityIncrement, 1.0)
        : stabilityIncrement;
    return _round8(
      _clampDouble(
        stabilityDays * maskedIncrement,
        _stabilityMin,
        _stabilityMax,
      ),
    );
  }

  /// Converts stability to a whole-day interval with fuzzing disabled.
  static int nextInterval(double stabilityDays) {
    final decay = -_weights[20];
    final factor = _round8(math.exp(math.log(0.9) / decay) - 1.0);
    final intervalModifier = _round8(
      (math.pow(requestedRetention, 1.0 / decay).toDouble() - 1.0) / factor,
    );
    final interval = (stabilityDays * intervalModifier).round();
    return math.min(math.max(1, interval), maximumIntervalDays);
  }

  static ReviewScheduleResult _fallback(String reason) {
    return ReviewScheduleResult(
      interval: conservativeInterval,
      nextState: null,
      usedConservativeFallback: true,
      fallbackReason: reason,
    );
  }

  static String? _stateInvalidReason(ReviewMemoryState state) {
    if (state.schemaVersion != ReviewMemoryState.currentSchemaVersion) {
      return 'unsupported scheduler state version';
    }
    if (!state.stabilityDays.isFinite ||
        state.stabilityDays < _stabilityMin ||
        state.stabilityDays > _stabilityMax) {
      return 'invalid scheduler stability';
    }
    if (!state.difficulty.isFinite ||
        state.difficulty < 1.0 ||
        state.difficulty > 10.0) {
      return 'invalid scheduler difficulty';
    }
    if (state.repetitions < 0 || state.lapses < 0) {
      return 'invalid scheduler counters';
    }
    return null;
  }

  static double _clampDouble(double value, double lower, double upper) {
    return math.max(lower, math.min(upper, value));
  }

  static double _round8(double value) {
    return (value * 100000000.0).roundToDouble() / 100000000.0;
  }
}
