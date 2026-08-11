// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;

    tempDir = await Directory.systemTemp.createTemp('benchmark_test');

    // Mock path_provider
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationSupportDirectory' ||
              methodCall.method == 'getDatabasesPath') {
            return tempDir.path;
          }
          return '.';
        });

    // Manually copy the database file for testing
    final dbBytes = await File(
      'assets/curriculum/ontario_curriculum.sqlite',
    ).readAsBytes();
    final dbPath = '${tempDir.path}/ontario_curriculum.sqlite';
    await File(dbPath).writeAsBytes(dbBytes, flush: true);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
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

    print(
      'Average time elapsed per call (CurriculumLoader): ${totalTime / iterations / 1000}ms',
    );
  });

  test('Benchmark courseDetailProvider', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
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

    print(
      'Time taken for 50 iterations (courseDetailProvider): ${stopwatch.elapsedMilliseconds} ms',
    );
    print(
      'Average time per iteration: ${stopwatch.elapsedMilliseconds / 50} ms',
    );
  });
}
