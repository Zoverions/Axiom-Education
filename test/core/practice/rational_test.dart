import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/rational.dart';

void main() {
  group('Rational', () {
    test('normalizes signs and common factors', () {
      expect(Rational(6, -8), Rational(-3, 4));
      expect(Rational(0, -9), Rational(0));
    });

    test('parses integers, fractions, and exact decimals', () {
      expect(Rational.tryParse('-7'), Rational(-7));
      expect(Rational.tryParse('6/8'), Rational(3, 4));
      expect(Rational.tryParse('0.75'), Rational(3, 4));
      expect(Rational.tryParse('-.5'), Rational(-1, 2));
    });

    test('rejects malformed and zero-denominator inputs', () {
      expect(Rational.tryParse(''), isNull);
      expect(Rational.tryParse('1/0'), isNull);
      expect(Rational.tryParse('1.2.3'), isNull);
      expect(() => Rational(1, 0), throwsArgumentError);
    });

    test('performs exact arithmetic', () {
      expect(Rational(1, 3) + Rational(1, 6), Rational(1, 2));
      expect(Rational(3, 4) - Rational(5, 8), Rational(1, 8));
      expect(Rational(2, 3) * Rational(9, 4), Rational(3, 2));
      expect(Rational(2, 3) / Rational(4, 5), Rational(5, 6));
    });
  });
}
