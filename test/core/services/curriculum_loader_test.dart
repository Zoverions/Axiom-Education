import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables
    await db.execute('''
      CREATE TABLE Course (
        id TEXT PRIMARY KEY,
        name TEXT,
        official_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Strand (
        id TEXT PRIMARY KEY,
        course_id TEXT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Expectation (
        id TEXT PRIMARY KEY,
        course_id TEXT,
        strand_id TEXT,
        text TEXT,
        irt_a REAL,
        irt_b REAL,
        irt_c REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE Tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expectation_id TEXT,
        tag TEXT
      )
    ''');

    // Insert test data
    await db.insert('Course', {
      'id': 'MTH1W',
      'name': 'Mathematics',
      'official_url': 'https://example.com/mth1w'
    });

    await db.insert('Course', {
      'id': 'ENG1D',
      'name': 'English',
      'official_url': null
    });

    await db.insert('Strand', {
      'id': 'S1',
      'course_id': 'MTH1W',
      'name': 'Number Sense'
    });

    await db.insert('Expectation', {
      'id': 'E1',
      'course_id': 'MTH1W',
      'strand_id': 'S1',
      'text': 'Test expectation 1',
      'irt_a': 1.0,
      'irt_b': 0.0,
      'irt_c': 0.2
    });

    await db.insert('Tag', {
      'expectation_id': 'E1',
      'tag': 'math'
    });

    await db.insert('Tag', {
      'expectation_id': 'E1',
      'tag': 'numbers'
    });

    // Inject DB
    DatabaseService.setDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('CurriculumLoader verificationNote is correct', () {
    expect(
        CurriculumLoader.verificationNote,
        contains('© King\'s Printer for Ontario'));
  });

  test('getExpectationsForCourse returns correct data', () async {
    final results = await CurriculumLoader.getExpectationsForCourse('MTH1W');

    expect(results.length, 1);
    expect(results[0]['id'], 'E1');
    expect(results[0]['expectation'], 'Test expectation 1');
    expect(results[0]['strand'], 'Number Sense');
    expect(results[0]['irt_a'], 1.0);
    expect(results[0]['irt_b'], 0.0);
    expect(results[0]['irt_c'], 0.2);
    expect(results[0]['tags'], ['math', 'numbers']);
  });

  test('getExpectationsForCourse returns empty list for unknown course', () async {
    final results = await CurriculumLoader.getExpectationsForCourse('UNKNOWN');
    expect(results, isEmpty);
  });

  test('officialUrl returns correct url if present', () async {
    final url = await CurriculumLoader.officialUrl('MTH1W');
    expect(url, 'https://example.com/mth1w');
  });

  test('officialUrl returns default url if not present', () async {
    final url = await CurriculumLoader.officialUrl('ENG1D');
    expect(url, 'https://www.ontario.ca/page/secondary-school-curriculum');
  });

  test('officialUrl returns default url for unknown course', () async {
    final url = await CurriculumLoader.officialUrl('UNKNOWN');
    expect(url, 'https://www.ontario.ca/page/secondary-school-curriculum');
  });
}
