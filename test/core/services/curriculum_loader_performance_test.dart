import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ontarioedai/core/services/curriculum_loader.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database db;

  setUpAll(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
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

    const int numExpectations = 100;
    const int tagsPerExpectation = 5;

    await db.transaction((txn) async {
      await txn.insert('Course', {'id': 'MTH1W', 'name': 'Mathematics'});
      await txn.insert('Strand', {'id': 'S1', 'course_id': 'MTH1W', 'name': 'Strand A'});
      for (var i = 0; i < numExpectations; i++) {
        final id = 'E$i';
        await txn.insert('Expectation', {
          'id': id,
          'course_id': 'MTH1W',
          'strand_id': 'S1',
          'text': 'Expectation $i',
          'irt_a': 1.0,
          'irt_b': 0.0,
          'irt_c': 0.2,
        });
        for (var j = 0; j < tagsPerExpectation; j++) {
          await txn.insert('Tag', {'expectation_id': id, 'tag': 'tag_$j'});
        }
      }
    });

    DatabaseService.setDatabase(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('Functionality and Performance check', () async {
    // Correctness
    final results = await CurriculumLoader.getExpectationsForCourse('MTH1W');
    expect(results.length, 100);
    expect(results[0]['tags'].length, 5);
    expect(results[0]['id'], startsWith('E'));
    expect(results[0]['expectation'], startsWith('Expectation'));
    expect(results[0].containsKey('tag'), isFalse);
    expect(results[0].containsKey('tags'), isTrue);

    // Warm up for performance (informational)
    final stopwatch = Stopwatch()..start();
    const iterations = 10;
    for (int i = 0; i < iterations; i++) {
      await CurriculumLoader.getExpectationsForCourse('MTH1W');
    }
    print('CurriculumLoader.getExpectationsForCourse (100 exps, 500 tags): ${stopwatch.elapsedMilliseconds / iterations} ms per call');
  });
}
