class Verification {
  static bool verify(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      print('Verification Failed: Data is empty or null.');
      return false;
    }

    // Basic verification checks
    if (!data.containsKey('id') || !data.containsKey('timestamp')) {
       print('Verification Failed: Missing required fields (id, timestamp).');
       return false;
    }

    final timestamp = data['timestamp'];
    if (timestamp is! int) {
        print('Verification Failed: Invalid timestamp format.');
        return false;
    }

    // Ensure the timestamp is in the past (not from the future)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (timestamp > now) {
         print('Verification Failed: Timestamp is in the future.');
         return false;
    }

    print('Verification Passed: Data integrity check successful.');
    return true;
  }
}
