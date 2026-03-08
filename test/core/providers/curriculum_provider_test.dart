import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('Data classes', () {
    test('CourseOverview properties', () {
      final overview = CourseOverview('CGC1D', 'Geography', 10);
      expect(overview.id, 'CGC1D');
      expect(overview.name, 'Geography');
      expect(overview.expectationCount, 10);
    });

    test('CourseDetail properties', () {
      final exp = ExpectationDetail('text', ['tag1']);
      final strand = StrandDetail('strand1', [exp]);
      final detail = CourseDetail('id1', 'name1', [strand]);

      expect(detail.id, 'id1');
      expect(detail.name, 'name1');
      expect(detail.strands.first.name, 'strand1');
      expect(detail.strands.first.expectations.first.text, 'text');
      expect(detail.strands.first.expectations.first.tags, contains('tag1'));
    });

    test('CurriculumFilter properties', () {
      final filter = CurriculumFilter(courseCode: 'ENG1D', tag: 'reading');
      expect(filter.courseCode, 'ENG1D');
      expect(filter.tag, 'reading');
      expect(filter.minDifficulty, -4.0);
      expect(filter.maxDifficulty, 4.0);

      final around = CurriculumFilter.aroundTheta(1.0, courseCode: 'ENG1D');
      expect(around.minDifficulty, -0.5);
      expect(around.maxDifficulty, 2.5);
      expect(around.courseCode, 'ENG1D');
    });

    test('CurriculumItem toIrtItem', () {
      final item = CurriculumItem(
        id: 'id1', courseCode: 'code1', strand: 's1',
        expectation: 'exp1', irtB: 1.0, irtA: 1.2, irtC: 0.2, tags: ['tag1']
      );
      final map = item.toIrtItem();
      expect(map['id'], 'id1');
      expect(map['b'], 1.0);
      expect(map['a'], 1.2);
      expect(map['c'], 0.2);
      expect(map['text'], 'exp1');
    });
  });

  group('Database initialization & Riverpod providers', () {
    test('database provider initializes, copies db from assets and returns correct records', () async {
      final tempDir = Directory.systemTemp.createTempSync('ontarioedai_test_db');
      final dbPath = p.join(tempDir.path, 'ontario_curriculum.sqlite');

      // Create an asset DB to copy from
      final assetDir = Directory.systemTemp.createTempSync('ontarioedai_test_asset');
      final assetDbPath = p.join(assetDir.path, 'source.sqlite');

      final sourceDb = await databaseFactory.openDatabase(assetDbPath, options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE Course (id TEXT, name TEXT)');
          await db.execute('CREATE TABLE Strand (id TEXT, course_id TEXT, name TEXT)');
          await db.execute('CREATE TABLE Expectation (id TEXT, strand_id TEXT, course_id TEXT, text TEXT, irt_b REAL, irt_a REAL, irt_c REAL)');
          await db.execute('CREATE TABLE Tag (id INTEGER PRIMARY KEY, expectation_id TEXT, tag TEXT)');

          // Insert test data
          await db.insert('Course', {'id': 'MTH1W', 'name': 'Math 9'});
          await db.insert('Strand', {'id': 's1', 'course_id': 'MTH1W', 'name': 'Strand 1'});
          await db.insert('Expectation', {
            'id': 'e1', 'strand_id': 's1', 'course_id': 'MTH1W',
            'text': 'Math expectation 1', 'irt_b': 1.0, 'irt_a': 1.2, 'irt_c': 0.2
          });
          await db.insert('Tag', {'expectation_id': 'e1', 'tag': 'math'});

          // Add another expectation for the same strand with a different tag
          await db.insert('Expectation', {
            'id': 'e2', 'strand_id': 's1', 'course_id': 'MTH1W',
            'text': 'Math expectation 2', 'irt_b': 2.0, 'irt_a': 1.0, 'irt_c': 0.1
          });
          await db.insert('Tag', {'expectation_id': 'e2', 'tag': 'math'});
          await db.insert('Tag', {'expectation_id': 'e2', 'tag': 'advanced'});
        }
      ));
      await sourceDb.close();

      final assetBytes = File(assetDbPath).readAsBytesSync();

      // Mock asset bundle so rootBundle.load returns our dummy test db
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          return ByteData.view(assetBytes.buffer);
        },
      );

      // Mock path provider to point db storage to our temp dir
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationSupportDirectory') {
            return tempDir.path;
          }
          if (methodCall.method == 'getDatabasesPath') {
            return tempDir.path;
          }
          return null;
        },
      );

      // Create a fresh ProviderContainer
      final container = ProviderContainer();

      // 1. Await database provider to let it initialize DatabaseService
      final db = await container.read(databaseProvider.future);
      expect(db.isOpen, isTrue);

      // 2. Await courseOverviewProvider
      final courseOverview = await container.read(courseOverviewProvider.future);
      expect(courseOverview.length, 1);
      expect(courseOverview.first.id, 'MTH1W');
      expect(courseOverview.first.expectationCount, 2);

      // 3. Await courseDetailProvider
      final courseDetail = await container.read(courseDetailProvider('MTH1W').future);
      expect(courseDetail.id, 'MTH1W');
      expect(courseDetail.strands.length, 1);
      expect(courseDetail.strands.first.expectations.length, 2);
      expect(courseDetail.strands.first.expectations.first.text, 'Math expectation 1');
      expect(courseDetail.strands.first.expectations.first.tags, contains('math'));
      expect(courseDetail.strands.first.expectations.last.tags, contains('advanced'));

      // 4. Test courseDetailProvider with an unknown ID
      final unknownCourseDetail = await container.read(courseDetailProvider('UNKNOWN').future);
      expect(unknownCourseDetail.id, 'UNKNOWN');
      expect(unknownCourseDetail.name, 'Unknown');
      expect(unknownCourseDetail.strands, isEmpty);

      // 5. Await curriculumBankProvider
      final bank = await container.read(curriculumBankProvider.future);
      expect(bank.length, 2);
      expect(bank.firstWhere((e) => e.id == 'e1').expectation, 'Math expectation 1');
      expect(bank.firstWhere((e) => e.id == 'e1').tags, contains('math'));
      expect(bank.firstWhere((e) => e.id == 'e1').irtB, 1.0);

      expect(bank.firstWhere((e) => e.id == 'e2').expectation, 'Math expectation 2');
      expect(bank.firstWhere((e) => e.id == 'e2').tags, containsAll(['math', 'advanced']));

      // 6. Test filteredItemsProvider
      final filter1 = CurriculumFilter(courseCode: 'MTH1W', tag: 'math');
      final filtered1Async = container.read(filteredItemsProvider(filter1));
      expect(filtered1Async.value?.length, 2);

      final filter2 = CurriculumFilter(courseCode: 'ENG1D');
      final filtered2Async = container.read(filteredItemsProvider(filter2));
      expect(filtered2Async.value?.length, 0);

      final filter3 = CurriculumFilter(courseCode: 'MTH1W', tag: 'advanced', minDifficulty: 1.5, maxDifficulty: 2.5);
      final filtered3Async = container.read(filteredItemsProvider(filter3));
      expect(filtered3Async.value?.length, 1);
      expect(filtered3Async.value?.first.id, 'e2');

      // Clean up temp dirs
      tempDir.deleteSync(recursive: true);
      assetDir.deleteSync(recursive: true);
    });
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

class MockPathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return '/mock/support/dir';
  }

  @override
  Future<String?> getDatabasesPath() async {
    return '/mock/databases/dir';
  }
}

class _MockDirectory implements Directory {
  final String _path;
  _MockDirectory(this._path);
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';

// Mock path provider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _appSupportPath;

  MockPathProviderPlatform(this._appSupportPath);

  @override
  Future<String?> getApplicationSupportPath() async {
    return _appSupportPath;
  }
}

// Mock Directory to throw on create
class ThrowingDirectory implements Directory {
  final String _path;

  ThrowingDirectory(this._path);

  @override
  String get path => _path;

  @override
  Future<Directory> create({bool recursive = false}) async {
    throw FileSystemException('Mock directory creation error', _path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockFile implements File {
  final String _path;
  final Function(List<int>) onWriteAsBytes;

  _MockFile(this._path, this.onWriteAsBytes);

  @override
  String get path => _path;

  @override
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) async {
    onWriteAsBytes(bytes);
    return this;
  }
    throw PathAccessException(path, const OSError(), 'Simulated creation failure');
  }

  // Ensure it reports not existing so that file write will fail naturally
  @override
  bool existsSync() => false;

  @override
  Future<bool> exists() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('DatabaseService._initDB handles directory creation exception', () async {
    // Provide mock asset data
    final mockDbData = Uint8List.fromList([1, 2, 3, 4]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        return mockDbData.buffer.asByteData();
      },
    );

    bool fileWritten = false;
    bool exceptionThrown = false;

    await IOOverrides.runZoned(
      () async {
        try {
          await DatabaseService.database;
        } catch (e) {
          // Expected because openDatabase will fail on fake bytes
        }
      },
      createDirectory: (String path) {
        exceptionThrown = true;
        return _MockDirectory(path);
      },
      createFile: (String path) {
        return _MockFile(path, (bytes) {
          fileWritten = true;
        });
      },
    );

    expect(exceptionThrown, isTrue, reason: 'Directory creation should have been attempted');
    expect(fileWritten, isTrue, reason: 'File should be written even if directory creation fails');
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseService handles directory creation failure gracefully and handles subsequent file write errors', () async {
    // We intentionally create a path where the parent directory does not exist.
    // In normal flutter test, systemTemp exists, but we can append a random non-existent directory.
    final tempDir = Directory(join(Directory.systemTemp.path, 'non_existent_curriculum_dir_12345'));

    // Set up mock path provider so getApplicationSupportDirectory returns our missing temp dir
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    // We override getDatabasesPath globally to point to our temp dir as well
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();

    // Mock the root bundle so it doesn't fail loading the asset
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        return ByteData(0); // Return empty byte array for sqlite copy
      },
    );

    bool createDirectoryCalled = false;

    await IOOverrides.runZoned(
      () async {
        final container = ProviderContainer();

        // This will attempt to create the database in a directory that fails to be created.
        // The File.writeAsBytes should naturally throw PathNotFoundException since we're pointing
        // it to a directory that wasn't created.
        final db = await container.read(databaseProvider.future);

        expect(db, isNotNull);
        expect(db.isOpen, isTrue);

        await db.close();
      },
      createDirectory: (String path) {
        // We throw an error when attempting to create the db directory
        // This simulates the missing edge case for directory creation error
        createDirectoryCalled = true;
        return ThrowingDirectory(path);
      },
    );

    expect(createDirectoryCalled, isTrue, reason: 'Directory create should have been called and intercepted');

    // Cleanup if anything accidentally got created (it shouldn't have been)
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
}
