import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// Create a Fake that throws UnimplementedError for any method called except ones we need
class FakeInterpreter extends Fake implements Interpreter {
  // We don't need to implement anything because decodeImage error happens before any method is called on Interpreter
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatcherModel Tests', () {
    test('parseCanvas with invalid image returns error message', () async {
      final model = WatcherModel();

      // Inject fake interpreter to bypass initialization check
      model.setInterpreterForTest(FakeInterpreter());

      // Pass an invalid/empty Uint8List which will fail decoding in img.decodeImage
      final Uint8List invalidImage = Uint8List(0);

      final result = await model.parseCanvas(invalidImage);

      expect(result, "Failed to decode image");
    });
  });
}
