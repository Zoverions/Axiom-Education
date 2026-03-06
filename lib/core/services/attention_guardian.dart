import 'dart:async';
import 'package:flutter/foundation.dart';

class AttentionGuardian extends ChangeNotifier {
  Timer? _focusTimer;
  int _focusedSeconds = 0;
  bool _isActive = false;

  int get focusedSeconds => _focusedSeconds;
  bool get isActive => _isActive;

  void startMonitoring() {
    if (_isActive) return;
    _isActive = true;
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _focusedSeconds++;
      notifyListeners();

      // Every 20 minutes (1200 seconds), trigger a focus check (placeholder for logic)
      if (_focusedSeconds % 1200 == 0) {
        _triggerFocusCheck();
      }
    });
    print('Attention Guardian: Monitoring started.');
  }

  void stopMonitoring() {
    _focusTimer?.cancel();
    _isActive = false;
    print('Attention Guardian: Monitoring stopped. Total focus time: ${_focusedSeconds}s');
    notifyListeners();
  }

  void reset() {
    _focusedSeconds = 0;
    notifyListeners();
  }

  void _triggerFocusCheck() {
    print('Attention Guardian: Focus check triggered! Consider taking a break.');
    // Logic to show a dialog or notification could be wired up here
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }
}
