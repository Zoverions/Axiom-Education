import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';

void main() {
  group('WatcherModel', () {
    test('parseCanvas fails closed when uninitialized', () async {
      final watcher = WatcherModel();

      await expectLater(
        watcher.parseCanvas(Uint8List(0)),
        throwsA(
          isA<ModelUnavailableException>().having(
            (error) => error.capability,
            'capability',
            'canvas.watcher',
          ),
        ),
      );
    });
  });
}
