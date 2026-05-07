import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// Manual mock for OrtSession
class MockOrtSession extends Fake implements OrtSession {
  bool releaseCalled = false;

  @override
  void release() {
    releaseCalled = true;
  }
}

// Manual mock for Interpreter
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
    test('initModel handles exception gracefully', () async {
      final model = Phi3MiniModel();
      await expectLater(
        model.initModel(
          mockSessionLoader: (String path, OrtSessionOptions options) async {
            throw Exception('Simulated initialization failure');
          },
        ),
        completes,
      );
    });

    test('dispose releases session and resets initialization state', () async {
      final model = Phi3MiniModel();
      final mockSession = MockOrtSession();

      await model.initModel(
        mockSessionLoader: (path, options) async => mockSession,
      );

      expect(model.isInitialized, isTrue);

      model.dispose();

      expect(model.isInitialized, isFalse);
      expect(mockSession.releaseCalled, isTrue);
    });
  });

  group('HandwritingScorer', () {
    test('initModel error leaves it uninitialized and returns fallback scores',
        () async {
      final scorer = HandwritingScorer();
      await scorer.initModel(
        interpreterLoader: () async => throw Exception('Mock TFLite Load Failure'),
      );
      expect(scorer.isInitialized, isFalse);
      final scores = await scorer.scoreHandwriting([]);
      expect(scores, equals((0.8, 0.85)));
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

    late HandwritingScorer scorer;

    setUp(() {
      scorer = HandwritingScorer();
    });

    test('preprocessStrokes handles exactly 100 strokes without errors', () {
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
      expect(result[0][0].length, 3);
      expect(result[0][0][0], 0.0);
      expect(result[0][0][1], 0.0);
      expect(result[0][0][2], 0.5);
      expect(result[0][99][0], 99.0);
      expect(result[0][99][1], 99.0);
      expect(result[0][99][2], 0.5);
    });

    test('preprocessStrokes handles excessive strokes (>100) safely by truncating',
        () {
      final strokes = List.generate(
        150,
        (index) => {
          'x': index.toDouble(),
          'y': index.toDouble(),
          'pressure': 0.5,
        },
      );
      final result = scorer.preprocessStrokes(strokes);
      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0].length, 3);
      expect(result[0][99][0], 99.0);
      expect(result[0][99][1], 99.0);
      expect(result[0][99][2], 0.5);
    });

    test('preprocessStrokes handles fewer than 100 strokes correctly', () {
      final strokes = List.generate(
        50,
        (index) => {
          'x': index.toDouble(),
          'y': index.toDouble(),
          'pressure': 0.5,
        },
      );
      final result = scorer.preprocessStrokes(strokes);
      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0].length, 3);
      expect(result[0][49][0], 49.0);
      expect(result[0][49][1], 49.0);
      expect(result[0][49][2], 0.5);
      expect(result[0][50][0], 0.0);
      expect(result[0][50][1], 0.0);
      expect(result[0][50][2], 0.0);
    });
  });

  group('WatcherModel', () {
    test('dispose closes interpreter and resets initialization state', () async {
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
