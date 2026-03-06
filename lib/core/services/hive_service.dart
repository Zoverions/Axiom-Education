import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HiveService {
  static Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      Hive.init(dir.path);
    } else {
      await Hive.initFlutter();
    }

    // Open default boxes
    await Hive.openBox('settings');
    await Hive.openBox('student_data');
  }
}
