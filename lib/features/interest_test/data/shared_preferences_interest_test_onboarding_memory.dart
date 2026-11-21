import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/interest_test_onboarding_memory.dart';

/// Persists per-account onboarding prompt state in [SharedPreferences].
// TODO(DP-078): Local per-uid fallback complementing server-side
// Users.InterestTestPrompted.
class SharedPreferencesInterestTestOnboardingMemory
    implements InterestTestOnboardingMemory {
  const SharedPreferencesInterestTestOnboardingMemory();

  static String _key(String userId) => 'interest_test.prompted.$userId';

  @override
  Future<bool> wasPrompted(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_key(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markPrompted(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_key(userId), true);
    } catch (_) {
      // Never block the user if local storage is unavailable.
    }
  }
}
