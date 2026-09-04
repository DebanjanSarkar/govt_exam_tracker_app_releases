import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

// Synchronous provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

class AiCooldownNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  Timer? _timer;

  AiCooldownNotifier(this._prefs) : super(0) {
    _initializeTimerFromStorage();
  }

  void _initializeTimerFromStorage() {
    final lastCallMillis = _prefs.getInt(AppConstants.prefsLastAiCallKey) ?? 0;
    if (lastCallMillis > 0) {
      final lastCallTime = DateTime.fromMillisecondsSinceEpoch(lastCallMillis);
      final elapsedSeconds = DateTime.now().difference(lastCallTime).inSeconds;
      final remaining = AppConstants.aiCooldownSeconds - elapsedSeconds;

      if (remaining > 0) {
        state = remaining;
        _startTicking();
      } else {
        state = 0; // Cooldown expired while app was closed
      }
    }
  }

  void startGlobalCooldown() {
    // Save the exact moment the AI was triggered to persistent storage
    _prefs.setInt(AppConstants.prefsLastAiCallKey, DateTime.now().millisecondsSinceEpoch);
    state = AppConstants.aiCooldownSeconds;
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// The global provider that any screen can listen to
final aiCooldownProvider = StateNotifierProvider<AiCooldownNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiCooldownNotifier(prefs);
});