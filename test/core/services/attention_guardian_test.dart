import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:ontarioedai/core/services/attention_guardian.dart';

void main() {
  group('AttentionGuardian', () {
    late AttentionGuardian guardian;

    setUp(() {
      guardian = AttentionGuardian();
    });

    tearDown(() {
      guardian.dispose();
    });

    test('Initial State: isActive is false and focusedSeconds is 0', () {
      expect(guardian.isActive, isFalse);
      expect(guardian.focusedSeconds, 0);
    });

    test(
      'startMonitoring: sets isActive to true and increments focusedSeconds',
      () {
        fakeAsync((async) {
          guardian.startMonitoring();
          expect(guardian.isActive, isTrue);

          async.elapse(const Duration(seconds: 1));
          expect(guardian.focusedSeconds, 1);

          async.elapse(const Duration(seconds: 59));
          expect(guardian.focusedSeconds, 60);
        });
      },
    );

    test('startMonitoring: duplicate calls do not create multiple timers', () {
      fakeAsync((async) {
        guardian.startMonitoring();
        guardian.startMonitoring(); // Duplicate call

        expect(guardian.isActive, isTrue);

        async.elapse(const Duration(seconds: 1));
        expect(guardian.focusedSeconds, 1); // Should still be 1, not 2
      });
    });

    test('stopMonitoring: stops the timer and sets isActive to false', () {
      fakeAsync((async) {
        guardian.startMonitoring();
        async.elapse(const Duration(seconds: 10));
        expect(guardian.focusedSeconds, 10);
        expect(guardian.isActive, isTrue);

        guardian.stopMonitoring();
        expect(guardian.isActive, isFalse);

        async.elapse(const Duration(seconds: 10));
        expect(guardian.focusedSeconds, 10); // Should not have changed
      });
    });

    test('reset: sets focusedSeconds to 0', () {
      fakeAsync((async) {
        guardian.startMonitoring();
        async.elapse(const Duration(seconds: 10));
        expect(guardian.focusedSeconds, 10);

        guardian.reset();
        expect(guardian.focusedSeconds, 0);
        expect(guardian.isActive, isTrue); // reset doesn't stop monitoring

        async.elapse(const Duration(seconds: 1));
        expect(guardian.focusedSeconds, 1);
      });
    });

    test('dispose: cancels the timer', () {
      fakeAsync((async) {
        // Create a new instance for this test to be sure
        final localGuardian = AttentionGuardian();
        localGuardian.startMonitoring();
        async.elapse(const Duration(seconds: 5));
        expect(localGuardian.focusedSeconds, 5);

        localGuardian.dispose();

        // If we try to advance time, no more timers should fire
        // In fake_async, if we advance and nothing happens, that's what we want.
        // We can't easily check 'isCancelled' but we can check side effects.
        async.elapse(const Duration(seconds: 10));
        // Note: we can't access localGuardian properties after dispose safely
        // if they notify listeners, but focusedSeconds is just a getter.
        expect(localGuardian.focusedSeconds, 5);
      });
    });

    test('focus check: triggers every 1200 seconds', () {
      final logs = <String>[];

      runZoned(
        () {
          fakeAsync((async) {
            guardian.startMonitoring();

            // Advance by 1199 seconds - no focus check yet
            async.elapse(const Duration(seconds: 1199));
            expect(
              logs.any((log) => log.contains('Focus check triggered!')),
              isFalse,
            );

            // Advance by 1 more second - triggers focus check
            async.elapse(const Duration(seconds: 1));
            expect(
              logs.any((log) => log.contains('Focus check triggered!')),
              isTrue,
            );

            logs.clear();

            // Advance by another 1200 seconds - triggers focus check again
            async.elapse(const Duration(seconds: 1200));
            expect(
              logs.any((log) => log.contains('Focus check triggered!')),
              isTrue,
            );
          });
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
    });
  });
}
