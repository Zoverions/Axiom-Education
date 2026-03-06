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
  });
}
