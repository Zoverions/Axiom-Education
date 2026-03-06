import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
