// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;

    tempDir = await Directory.systemTemp.createTemp('benchmark_url_test');

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
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Benchmark officialUrl', () async {
    // Warmup
    await CurriculumLoader.officialUrl('BEP2O');

    int totalTime = 0;
    const iterations = 500;

    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      await CurriculumLoader.officialUrl('BEP2O');
      stopwatch.stop();
      totalTime += stopwatch.elapsedMicroseconds;
    }

    print(
      'Average time elapsed per call (officialUrl): ${totalTime / iterations / 1000}ms',
    );
  });
}
