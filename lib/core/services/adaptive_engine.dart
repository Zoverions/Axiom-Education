import 'dart:math';
import '../models/student_profile.dart';

class AdaptiveEngine {
  static double updateTheta({
    required double currentTheta,
    required List<double> responses,
    required List<double> difficulties,
  }) {
    // Basic placeholder implementation for theta update.
    double newTheta = currentTheta;
    for (int i = 0; i < responses.length; i++) {
      double r = responses[i];
      double b = difficulties[i];
      // simple heuristic update
      if (r == 1.0) {
        newTheta += 0.1 * (1.0 / (1.0 + exp(currentTheta - b)));
      } else {
        newTheta -=
            0.1 * (exp(currentTheta - b) / (1.0 + exp(currentTheta - b)));
      }
    }
    return newTheta;
  }

  static Duration sessionLength(StudentProfile profile) {
    return const Duration(minutes: 15);
  }

  static String ontarioLevel(double theta) {
    if (theta > 1.5) return 'Level 4 (80-100%)';
    if (theta > 0.0) return 'Level 3 (70-79%)';
    if (theta > -1.0) return 'Level 2 (60-69%)';
    return 'Level 1 (50-59%)';
  }

  static Duration nextReviewInterval(int questionsAnswered, double factor) {
    return Duration(days: max(1, (questionsAnswered * factor).round()));
  }
}
