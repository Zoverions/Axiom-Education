class Rational {
  Rational(int numerator, [int denominator = 1])
      : assert(denominator != 0, 'denominator must not be zero'),
        numerator = _normalizedNumerator(numerator, denominator),
        denominator = _normalizedDenominator(numerator, denominator);

  final int numerator;
  final int denominator;

  static Rational? tryParse(String input) {
    final value = input.trim().replaceAll(' ', '');
    if (value.isEmpty) return null;

    final fractionMatch = RegExp(r'^([+-]?\d+)(?:/([+-]?\d+))?$').firstMatch(value);
    if (fractionMatch != null) {
      final numerator = int.tryParse(fractionMatch.group(1)!);
      final denominator = int.tryParse(fractionMatch.group(2) ?? '1');
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return Rational(numerator, denominator);
    }

    final decimalMatch = RegExp(r'^([+-]?)(\d+)\.(\d+)$').firstMatch(value);
    if (decimalMatch == null) return null;

    final sign = decimalMatch.group(1) == '-' ? -1 : 1;
    final whole = decimalMatch.group(2)!;
    final fractional = decimalMatch.group(3)!;
    final denominator = _powerOfTen(fractional.length);
    final numerator = sign * int.parse('$whole$fractional');
    return Rational(numerator, denominator);
  }

  Rational operator +(Rational other) => Rational(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Rational operator -(Rational other) => Rational(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  Rational operator *(Rational other) => Rational(
        numerator * other.numerator,
        denominator * other.denominator,
      );

  Rational operator /(Rational other) {
    if (other.numerator == 0) {
      throw const FormatException('Cannot divide by zero.');
    }
    return Rational(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  Rational operator -() => Rational(-numerator, denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => denominator == 1 ? '$numerator' : '$numerator/$denominator';

  static int _normalizedNumerator(int numerator, int denominator) {
    final divisor = _greatestCommonDivisor(numerator.abs(), denominator.abs());
    final sign = denominator < 0 ? -1 : 1;
    return sign * numerator ~/ divisor;
  }

  static int _normalizedDenominator(int numerator, int denominator) {
    final divisor = _greatestCommonDivisor(numerator.abs(), denominator.abs());
    return denominator.abs() ~/ divisor;
  }

  static int _greatestCommonDivisor(int a, int b) {
    if (a == 0) return b == 0 ? 1 : b;
    var left = a;
    var right = b;
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left.abs();
  }

  static int _powerOfTen(int exponent) {
    var result = 1;
    for (var index = 0; index < exponent; index += 1) {
      result *= 10;
    }
    return result;
  }
}
