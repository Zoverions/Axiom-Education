import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MockOrtSession extends Fake implements OrtSession {
  bool releaseCalled = false;

  @override
  void release() {
    releaseCalled = true;
  }
}

class MockInterpreter extends Fake implements Interpreter {
  bool closeCalled = false;

  @override
  void close() {
    closeCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phi3MiniModel', () {
    test('initModel surfaces initialization failure and remains unavailable',
        () async {
      final model = Phi3MiniModel();

      await expectLater(
        model.initModel(
          testSessionLoader: () async {
            throw Exception('Simulated initialization failure');
          },
        ),
        throwsA(isA<ModelUnavailableException>()),
      );
      expect(model.isInitialized, isFalse);
    });

    test('dispose releases an injected session and resets state', () async {
      final model = Phi3MiniModel();
      final mockSession = MockOrtSession();

      await model.initModel(
        testSessionLoader: () async => mockSession,
      );
      expect(model.isInitialized, isTrue);

      model.dispose();

      expect(model.isInitialized, isFalse);
      expect(mockSession.releaseCalled, isTrue);
    });
  });

  group('HandwritingScorer', () {
    test('initialization failure is explicit and leaves scorer unavailable',
        () async {
      final scorer = HandwritingScorer();

      await expectLater(
        scorer.initModel(
          interpreterLoader: () async {
            throw Exception('Mock TFLite load failure');
          },
        ),
        throwsA(isA<ModelUnavailableException>()),
      );
      expect(scorer.isInitialized, isFalse);
      await expectLater(
        scorer.scoreHandwriting(const []),
        throwsA(isA<ModelUnavailableException>()),
      );
    });

    test('dispose closes interpreter and resets initialization state', () async {
      final scorer = HandwritingScorer();
      final mockInterpreter = MockInterpreter();

      await scorer.initModel(
        interpreterLoader: () async => mockInterpreter,
      );
      expect(scorer.isInitialized, isTrue);

      scorer.dispose();

      expect(scorer.isInitialized, isFalse);
      expect(mockInterpreter.closeCalled, isTrue);
    });

    test('preprocessStrokes accepts exactly 100 bounded strokes', () {
      final scorer = HandwritingScorer();
      final strokes = List.generate(
        100,
        (index) => {
          'x': index.toDouble(),
          'y': index.toDouble(),
          'pressure': 0.5,
        },
      );

      final result = scorer.preprocessStrokes(strokes);

      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0], [0.0, 0.0, 0.5]);
      expect(result[0][99], [99.0, 99.0, 0.5]);
    });

    test('preprocessStrokes rejects excessive strokes instead of truncating', () {
      final scorer = HandwritingScorer();
      final strokes = List.generate(
        101,
        (index) => {
          'x': index.toDouble(),
          'y': index.toDouble(),
          'pressure': 0.5,
        },
      );

      expect(
        () => scorer.preprocessStrokes(strokes),
        throwsFormatException,
      );
    });

    test('preprocessStrokes zero-pads unused rows', () {
      final scorer = HandwritingScorer();
      final strokes = List.generate(
        50,
        (index) => {
          'x': index.toDouble(),
          'y': index.toDouble(),
          'pressure': 0.5,
        },
      );

      final result = scorer.preprocessStrokes(strokes);

      expect(result[0][49], [49.0, 49.0, 0.5]);
      expect(result[0][50], [0.0, 0.0, 0.0]);
    });
  });

  group('WatcherModel', () {
    test('dispose closes interpreter and resets initialization state', () {
      final model = WatcherModel();
      final mockInterpreter = MockInterpreter();

      model.setInterpreterForTest(mockInterpreter);
      expect(model.isInitialized, isTrue);

      model.dispose();

      expect(model.isInitialized, isFalse);
      expect(mockInterpreter.closeCalled, isTrue);
    });
  });
}
