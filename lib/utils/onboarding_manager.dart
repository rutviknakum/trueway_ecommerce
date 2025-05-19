import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to manage onboarding state across sessions
class OnboardingManager {
  // Keys for shared preferences
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  
  /// Check if the user has seen the onboarding screens
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }
  
  /// Mark that the user has seen the onboarding screens
  static Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
  
  /// Reset onboarding status (mostly for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, false);
  }
}
