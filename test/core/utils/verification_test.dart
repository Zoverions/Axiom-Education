import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/utils/verification.dart';

void main() {
  group('Verification Tests', () {
    List<String> printLogs = [];

    setUp(() {
      printLogs.clear();
    });

    bool runWithPrintInterception(Map<String, dynamic>? data) {
      return runZoned(
        () => Verification.verify(data),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            printLogs.add(line);
          },
        ),
      );
    }

    test('returns false and prints message when data is null', () {
      final result = runWithPrintInterception(null);
      expect(result, isFalse);
      expect(
        printLogs,
        contains('Verification Failed: Data is empty or null.'),
      );
    });

    test('returns false and prints message when data is empty', () {
      final result = runWithPrintInterception({});
      expect(result, isFalse);
      expect(
        printLogs,
        contains('Verification Failed: Data is empty or null.'),
      );
    });

    test('returns false and prints message when missing required fields', () {
      final result1 = runWithPrintInterception({'id': 1}); // missing timestamp
      expect(result1, isFalse);
      expect(
        printLogs,
        contains(
          'Verification Failed: Missing required fields (id, timestamp).',
        ),
      );

      printLogs.clear();
      final result2 = runWithPrintInterception({
        'timestamp': 1000,
      }); // missing id
      expect(result2, isFalse);
      expect(
        printLogs,
        contains(
          'Verification Failed: Missing required fields (id, timestamp).',
        ),
      );
    });

    test(
      'returns false and prints message when timestamp is invalid format',
      () {
        final result = runWithPrintInterception({
          'id': 1,
          'timestamp': 'not an int',
        });
        expect(result, isFalse);
        expect(
          printLogs,
          contains('Verification Failed: Invalid timestamp format.'),
        );
      },
    );

    test(
      'returns false and prints message when timestamp is in the future',
      () {
        final futureTimestamp = DateTime.now().millisecondsSinceEpoch + 10000;
        final result = runWithPrintInterception({
          'id': 1,
          'timestamp': futureTimestamp,
        });
        expect(result, isFalse);
        expect(
          printLogs,
          contains('Verification Failed: Timestamp is in the future.'),
        );
      },
    );

    test('returns true and prints message when data is valid', () {
      final pastTimestamp = DateTime.now().millisecondsSinceEpoch - 10000;
      final result = runWithPrintInterception({
        'id': 1,
        'timestamp': pastTimestamp,
      });
      expect(result, isTrue);
      expect(
        printLogs,
        contains('Verification Passed: Data integrity check successful.'),
      );
    });
  });
}
