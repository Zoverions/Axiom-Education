import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/services.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock path_provider channel to use a temporary directory
  final tempDir = Directory.systemTemp.createTempSync('ontarioedai_test_');

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return tempDir.path;
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    // Ensure we have a clean DB for tests or handle setup if needed.
    // The actual implementation loads from assets/curriculum/ontario_curriculum.sqlite
  });

  test('officialUrl returns fallback URL for missing course code', () async {
    final url = await CurriculumLoader.officialUrl('MISSING_COURSE_XYZ');
    expect(url, 'https://www.ontario.ca/page/secondary-school-curriculum');
  });

  test('officialUrl returns fallback URL when course exists but official_url is null', () async {
    final db = await DatabaseService.database;
    await db.insert('Course', {'id': 'NULL_URL_COURSE', 'name': 'Test Course', 'official_url': null});

    final url = await CurriculumLoader.officialUrl('NULL_URL_COURSE');
    expect(url, 'https://www.ontario.ca/page/secondary-school-curriculum');

    // cleanup
    await db.delete('Course', where: 'id = ?', whereArgs: ['NULL_URL_COURSE']);
  });

  test('officialUrl returns course official_url when course exists and has url', () async {
    final db = await DatabaseService.database;
    await db.insert('Course', {'id': 'TEST_COURSE', 'name': 'Test Course', 'official_url': 'https://example.com/course'});

    final url = await CurriculumLoader.officialUrl('TEST_COURSE');
    expect(url, 'https://example.com/course');

    // cleanup
    await db.delete('Course', where: 'id = ?', whereArgs: ['TEST_COURSE']);
  });
}
