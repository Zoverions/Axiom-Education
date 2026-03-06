import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Mock path provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          return Directory.current.path;
        }
        if (methodCall.method == 'getDatabasesPath') {
          return Directory.current.path;
        }
        return null;
      },
    );
  });

  test('Benchmark getExpectationsForCourse', () async {
    // Warmup
    await CurriculumLoader.getExpectationsForCourse('BEP2O');

    int totalTime = 0;
    const iterations = 50;

    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      await CurriculumLoader.getExpectationsForCourse('BEP2O');
      stopwatch.stop();
      totalTime += stopwatch.elapsedMicroseconds;
    }

    print('Average time elapsed per call: ${totalTime / iterations / 1000}ms');
  });
}
