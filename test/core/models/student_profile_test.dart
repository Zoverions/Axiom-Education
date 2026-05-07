import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/student_profile.dart';

void main() {
  group('StudentProfile', () {
    test('should have default values when no parameters are provided', () {
      final profile = StudentProfile();
      expect(profile.irtTheta, 0.0);
      expect(profile.irtBand, 'grade_level');
    });

    test('should use provided values in constructor', () {
      final profile = StudentProfile(irtTheta: 1.5, irtBand: 'advanced');
      expect(profile.irtTheta, 1.5);
      expect(profile.irtBand, 'advanced');
    });

    test('should support partial initialization with default values', () {
      final profileThetaOnly = StudentProfile(irtTheta: -0.5);
      expect(profileThetaOnly.irtTheta, -0.5);
      expect(profileThetaOnly.irtBand, 'grade_level');

      final profileBandOnly = StudentProfile(irtBand: 'remedial');
      expect(profileBandOnly.irtTheta, 0.0);
      expect(profileBandOnly.irtBand, 'remedial');
    });
  });
}
