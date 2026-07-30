import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;

  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class ThrowingDirectory extends Fake implements Directory {
  final String _path;

  ThrowingDirectory(this._path);

  @override
  String get path => _path;

  @override
  Future<Directory> create({bool recursive = false}) async {
    throw FileSystemException('Simulated directory creation failure', _path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await DatabaseService.resetForTesting();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('Data classes', () {
    test('CourseOverview exposes supplied properties', () {
      final overview = CourseOverview('CGC1D', 'Geography', 10);

      expect(overview.id, 'CGC1D');
      expect(overview.name, 'Geography');
      expect(overview.expectationCount, 10);
    });

    test('CourseDetail preserves strands, expectations, and tags', () {
      final expectation = ExpectationDetail('text', ['tag1']);
      final strand = StrandDetail('strand1', [expectation]);
      final detail = CourseDetail('id1', 'name1', [strand]);

      expect(detail.id, 'id1');
      expect(detail.name, 'name1');
      expect(detail.strands.single.name, 'strand1');
      expect(detail.strands.single.expectations.single.text, 'text');
      expect(detail.strands.single.expectations.single.tags, ['tag1']);
    });

    test('CurriculumFilter creates the expected theta window', () {
      const filter = CurriculumFilter(courseCode: 'ENG1D', tag: 'reading');
      expect(filter.minDifficulty, -4.0);
      expect(filter.maxDifficulty, 4.0);

      final around = CurriculumFilter.aroundTheta(
        1.0,
        courseCode: 'ENG1D',
      );
      expect(around.minDifficulty, -0.5);
      expect(around.maxDifficulty, 2.5);
      expect(around.courseCode, 'ENG1D');
    });

    test('CurriculumItem exposes its legacy heuristic map', () {
      const item = CurriculumItem(
        id: 'id1',
        courseCode: 'code1',
        strand: 's1',
        expectation: 'exp1',
        irtB: 1.0,
        irtA: 1.2,
        irtC: 0.2,
        tags: ['tag1'],
      );

      expect(item.toIrtItem(), {
        'id': 'id1',
        'b': 1.0,
        'a': 1.2,
        'c': 0.2,
        'text': 'exp1',
      });
    });
  });

  group('Database initialization and providers', () {
    test('copies and verifies the bundled database before serving providers',
        () async {
      final outputDirectory =
          Directory.systemTemp.createTempSync('ontarioedai-output-');
      final assetDirectory =
          Directory.systemTemp.createTempSync('ontarioedai-asset-');
      final assetDatabasePath = p.join(assetDirectory.path, 'source.sqlite');

      final sourceDatabase = await databaseFactory.openDatabase(
        assetDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) async {
            await database.execute(
              'CREATE TABLE Course (id TEXT, name TEXT)',
            );
            await database.execute(
              'CREATE TABLE Strand '
              '(id TEXT, course_id TEXT, name TEXT)',
            );
            await database.execute(
              'CREATE TABLE Expectation '
              '(id TEXT, strand_id TEXT, course_id TEXT, text TEXT, '
              'irt_b REAL, irt_a REAL, irt_c REAL)',
            );
            await database.execute(
              'CREATE TABLE Tag '
              '(id INTEGER PRIMARY KEY, expectation_id TEXT, tag TEXT)',
            );
            await database.insert('Course', {
              'id': 'MTH1W',
              'name': 'Math 9',
            });
            await database.insert('Strand', {
              'id': 's1',
              'course_id': 'MTH1W',
              'name': 'Strand 1',
            });
            await database.insert('Expectation', {
              'id': 'e1',
              'strand_id': 's1',
              'course_id': 'MTH1W',
              'text': 'Math expectation 1',
              'irt_b': 1.0,
              'irt_a': 1.2,
              'irt_c': 0.2,
            });
            await database.insert('Tag', {
              'expectation_id': 'e1',
              'tag': 'math',
            });
            await database.insert('Expectation', {
              'id': 'e2',
              'strand_id': 's1',
              'course_id': 'MTH1W',
              'text': 'Math expectation 2',
              'irt_b': 2.0,
              'irt_a': 1.0,
              'irt_c': 0.1,
            });
            await database.insert('Tag', {
              'expectation_id': 'e2',
              'tag': 'math',
            });
            await database.insert('Tag', {
              'expectation_id': 'e2',
              'tag': 'advanced',
            });
          },
        ),
      );
      await sourceDatabase.close();
      final assetBytes = File(assetDatabasePath).readAsBytesSync();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async => ByteData.sublistView(assetBytes),
      );
      PathProviderPlatform.instance =
          MockPathProviderPlatform(outputDirectory.path);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final database = await container.read(databaseProvider.future);
      expect(database.isOpen, isTrue);

      final overview = await container.read(courseOverviewProvider.future);
      expect(overview.single.id, 'MTH1W');
      expect(overview.single.expectationCount, 2);

      final detail = await container.read(courseDetailProvider('MTH1W').future);
      expect(detail.strands.single.expectations.length, 2);
      expect(detail.strands.single.expectations.last.tags, contains('advanced'));

      final unknown =
          await container.read(courseDetailProvider('UNKNOWN').future);
      expect(unknown.name, 'Unknown');
      expect(unknown.strands, isEmpty);

      final bank = await container.read(curriculumBankProvider.future);
      expect(bank.length, 2);
      expect(
        bank.firstWhere((item) => item.id == 'e2').tags,
        containsAll(['math', 'advanced']),
      );

      final filtered = container.read(
        filteredItemsProvider(
          const CurriculumFilter(
            courseCode: 'MTH1W',
            tag: 'advanced',
            minDifficulty: 1.5,
            maxDifficulty: 2.5,
          ),
        ),
      );
      expect(filtered.value?.single.id, 'e2');

      await DatabaseService.resetForTesting();
      outputDirectory.deleteSync(recursive: true);
      assetDirectory.deleteSync(recursive: true);
    });

    test('fails closed when the database directory cannot be created', () async {
      final missingPath = p.join(
        Directory.systemTemp.path,
        'ontarioedai-missing-${DateTime.now().microsecondsSinceEpoch}',
      );
      PathProviderPlatform.instance = MockPathProviderPlatform(missingPath);
      var createDirectoryCalled = false;

      await expectLater(
        IOOverrides.runZoned(
          () => DatabaseService.database,
          createDirectory: (path) {
            createDirectoryCalled = true;
            return ThrowingDirectory(path);
          },
        ),
        throwsA(isA<CurriculumDatabaseInitializationException>()),
      );
      expect(createDirectoryCalled, isTrue);
    });

    test('fails closed when the bundled database asset is empty', () async {
      final outputDirectory =
          Directory.systemTemp.createTempSync('ontarioedai-empty-');
      PathProviderPlatform.instance =
          MockPathProviderPlatform(outputDirectory.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async => ByteData(0),
      );

      await expectLater(
        DatabaseService.database,
        throwsA(isA<CurriculumDatabaseInitializationException>()),
      );

      outputDirectory.deleteSync(recursive: true);
    });
  });
}
