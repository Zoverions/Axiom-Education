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
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock path_provider
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  setUp(() async {
    // Manually copy the database file for testing
    final dbBytes = await File('assets/curriculum/ontario_curriculum.sqlite').readAsBytes();
    final outDir = Directory('.dart_tool/sqflite_common_ffi/databases');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    await File('.dart_tool/sqflite_common_ffi/databases/ontario_curriculum.sqlite').writeAsBytes(dbBytes);
  });

  test('Benchmark courseDetailProvider', () async {
    final container = ProviderContainer();
    // Warm up the database
    await container.read(databaseProvider.future);

    // Get all courses to test
    final courses = await container.read(courseOverviewProvider.future);
    print('Total courses: ${courses.length}');

    if (courses.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    // Run multiple iterations to get a more stable timing
    for (int i = 0; i < 50; i++) {
        for (var course in courses) {
            await container.read(courseDetailProvider(course.id).future);
        }
    }
    stopwatch.stop();

    print('Time taken for 50 iterations (N+1): ${stopwatch.elapsedMilliseconds} ms');
    print('Average time per iteration: ${stopwatch.elapsedMilliseconds / 50} ms');
  });
}
