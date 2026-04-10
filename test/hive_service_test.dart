import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/hive_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return './test_hive_dir';
  }
}

void main() {
  setUp(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  tearDown(() async {
    await Hive.close();
    final dir = Directory('./test_hive_dir');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('HiveService.init initializes hive and opens boxes', () async {
    await HiveService.init();

    expect(Hive.isBoxOpen('settings'), isTrue);
    expect(Hive.isBoxOpen('student_data'), isTrue);
  });
}
