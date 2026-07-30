import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String settingsBoxName = 'settings';

  static bool _configured = false;

  static Future<void> init() async {
    if (!_configured) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final directory = await getApplicationSupportDirectory();
        Hive.init(directory.path);
      } else {
        await Hive.initFlutter();
      }
      _configured = true;
    }

    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox<dynamic>(settingsBoxName);
    }
  }
}
