import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';
import 'package:onnxruntime/onnxruntime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Phi3MiniModel.initModel handles exception gracefully', () async {
    // Instantiate the actual model class
    final model = Phi3MiniModel();

    // Inject a mock loader that unconditionally throws an exception.
    // We expect the initModel method to catch the exception internally and complete normally
    // rather than throwing the exception out to the caller and crashing the app.
    await expectLater(
      model.initModel(mockSessionLoader: (String path, OrtSessionOptions options) async {
        throw Exception('Simulated initialization failure');
      }),
      completes
    );
  });
}
