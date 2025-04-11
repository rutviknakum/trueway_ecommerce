// init_app.dart - App initialization helper
// Add this file to your project to ensure proper initialization

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueway_ecommerce/services/api_service.dart';

class AppInitializer {
  static ApiService? _apiService;
  static bool _initialized = false;

  // Get the initialized API service
  static ApiService get apiService {
    if (!_initialized) {
      throw Exception(
        "AppInitializer not initialized! Call initialize() first.",
      );
    }
    return _apiService!;
  }

  // Initialize the app and its services
  static Future<void> initialize() async {
    if (_initialized) return;

    print("Starting app initialization...");

    // First check for any incomplete or corrupted user data
    await _ensureCleanUserData();

    // Initialize services
    _apiService = ApiService();
    await _apiService!.init();

    _initialized = true;
    print("App initialization completed successfully!");
  }

  // Helper to clean up potentially corrupted user data during app start
  static Future<void> _ensureCleanUserData() async {
    print("Checking for data consistency...");
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have partial user data
      bool hasEmail = prefs.containsKey('user_email');
      bool hasUserId = prefs.containsKey('user_id');
      bool hasCurrentUserId = prefs.containsKey('current_user_id');

      // If we have email but no user ID, we need to fix this
      if (hasEmail && (!hasUserId || !hasCurrentUserId)) {
        print(
          "Found inconsistent user data - email exists but user ID is missing",
        );

        // Get the email to generate a consistent ID
        final email = prefs.getString('user_email');
        if (email != null && email.isNotEmpty) {
          final generatedId = email.hashCode.toString();
          print("Generated user ID from email: $generatedId");

          if (!hasUserId) {
            await prefs.setString('user_id', generatedId);
          }

          if (!hasCurrentUserId) {
            await prefs.setString('current_user_id', generatedId);
          }

          print("Fixed user data consistency");
        } else {
          // If email is empty or null but the key exists, clean up
          print("Found empty email with missing user IDs - cleaning data");
          await _cleanAllUserData(prefs);
        }
      }
      // If we have user IDs but no email, that's strange - clean up
      else if (!hasEmail && (hasUserId || hasCurrentUserId)) {
        print("Found user IDs without email - cleaning corrupted data");
        await _cleanAllUserData(prefs);
      }

      // Ensure user_id and current_user_id match if both exist
      if (hasUserId && hasCurrentUserId) {
        final userId = prefs.getString('user_id');
        final currentUserId = prefs.getString('current_user_id');

        if (userId != currentUserId) {
          print("User ID mismatch detected - fixing");
          if (userId != null && userId.isNotEmpty) {
            await prefs.setString('current_user_id', userId);
          } else if (currentUserId != null && currentUserId.isNotEmpty) {
            await prefs.setString('user_id', currentUserId);
          }
        }
      }

      print("Data consistency check completed");
    } catch (e) {
      print("Error during data consistency check: $e");
    }
  }

  // Clean all user data
  static Future<void> _cleanAllUserData(SharedPreferences prefs) async {
    try {
      // Get the keys to remove
      final keys =
          prefs
              .getKeys()
              .where(
                (key) =>
                    key.startsWith('user_') ||
                    key == 'auth_token' ||
                    key == 'basic_auth' ||
                    key == 'customer_id' ||
                    key == 'is_local_user' ||
                    key == 'local_user_password' ||
                    key == 'current_user_id',
              )
              .toList();

      // Remove all the keys
      for (String key in keys) {
        await prefs.remove(key);
      }

      print("Cleaned all user data");
    } catch (e) {
      print("Error cleaning user data: $e");
    }
  }
}
