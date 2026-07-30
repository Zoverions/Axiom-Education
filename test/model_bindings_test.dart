import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FakeInterpreter extends Fake implements Interpreter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatcherModel', () {
    test('throws an unavailable error when uninitialized', () async {
      final model = WatcherModel();

      await expectLater(
        model.parseCanvas(Uint8List(0)),
        throwsA(
          isA<ModelUnavailableException>().having(
            (error) => error.capability,
            'capability',
            'canvas.watcher',
          ),
        ),
      );
    });

    test('reports invalid image data without a mock equation', () async {
      final model = WatcherModel()..setInterpreterForTest(FakeInterpreter());

      expect(await model.parseCanvas(Uint8List(0)), 'Failed to decode image');
    });

    test('rejects oversized encoded images before model access', () async {
      final model = WatcherModel();
      final image = Uint8List(WatcherModel.maxEncodedImageBytes + 1);

      expect(await model.parseCanvas(image), 'Image size too large');
    });
  });

  group('Phi3MiniModel', () {
    test('rejects empty prompts', () async {
      final model = Phi3MiniModel();

      await expectLater(
        model.generateResponse('   '),
        throwsFormatException,
      );
    });

    test('fails closed when the model is uninitialized', () async {
      final model = Phi3MiniModel();

      await expectLater(
        model.generateResponse('Explain slope.'),
        throwsA(
          isA<ModelUnavailableException>().having(
            (error) => error.capability,
            'capability',
            'tutor.local-inference',
          ),
        ),
      );
    });
  });
}
