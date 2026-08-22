import 'package:flutter/foundation.dart';

class Verification {
  static bool verify(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      debugPrint('Verification Failed: Data is empty or null.');
      return false;
    }

    // Basic verification checks
    if (!data.containsKey('id') || !data.containsKey('timestamp')) {
      debugPrint(
        'Verification Failed: Missing required fields (id, timestamp).',
      );
      return false;
    }

    final timestamp = data['timestamp'];
    if (timestamp is! int) {
      debugPrint('Verification Failed: Invalid timestamp format.');
      return false;
    }

    // Ensure the timestamp is in the past (not from the future)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (timestamp > now) {
      debugPrint('Verification Failed: Timestamp is in the future.');
      return false;
    }

    debugPrint('Verification Passed: Data integrity check successful.');
    return true;
  }
}
