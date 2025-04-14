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

      // Check for potentially corrupted/inconsistent auth data
      bool hasAuthToken = prefs.containsKey('auth_token');
      bool hasBasicAuth = prefs.containsKey('basic_auth');
      bool hasEmail = prefs.containsKey('user_email');
      bool hasUserId = prefs.containsKey('user_id');
      bool hasCurrentUserId = prefs.containsKey('current_user_id');
      bool isLocalUser = prefs.getBool('is_local_user') ?? false;

      // Check if we have auth tokens without user data
      if ((hasAuthToken || hasBasicAuth) && !hasEmail) {
        print("Found auth tokens without user email - cleaning corrupted data");
        await _cleanAllAuthData(prefs);
      }

      // If we have email but no user ID, we need to fix this
      if (hasEmail && (!hasUserId || !hasCurrentUserId)) {
        print(
          "Found inconsistent user data - email exists but user ID is missing",
        );

        // Get the email to generate a consistent ID
        final email = prefs.getString('user_email');
        if (email != null && email.isNotEmpty && email != 'null') {
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
          await _cleanAllAuthData(prefs);
        }
      }
      // If we have user IDs but no email, that's strange - clean up
      else if (!hasEmail && (hasUserId || hasCurrentUserId)) {
        print("Found user IDs without email - cleaning corrupted data");
        await _cleanAllAuthData(prefs);
      }

      // Ensure auth token is valid if marked as a local user
      if (isLocalUser) {
        String? authToken = prefs.getString('auth_token');
        String? userId = prefs.getString('user_id');

        // If local user but no valid auth token or user ID, clean up
        if (userId == null ||
            userId.isEmpty ||
            userId == 'null' ||
            authToken == null ||
            authToken.isEmpty ||
            authToken == 'null') {
          print("Found inconsistent local user data - cleaning up");
          await _cleanAllAuthData(prefs);
        }
        // Ensure local user has a token that follows the correct format
        else if (!authToken.startsWith('local_auth_')) {
          print("Fixing local user auth token format");
          await prefs.setString('auth_token', 'local_auth_$userId');
        }
      }

      // Ensure user_id and current_user_id match if both exist
      if (hasUserId && hasCurrentUserId) {
        final userId = prefs.getString('user_id');
        final currentUserId = prefs.getString('current_user_id');

        if (userId != currentUserId) {
          print("User ID mismatch detected - fixing");
          if (userId != null && userId.isNotEmpty && userId != 'null') {
            await prefs.setString('current_user_id', userId);
          } else if (currentUserId != null &&
              currentUserId.isNotEmpty &&
              currentUserId != 'null') {
            await prefs.setString('user_id', currentUserId);
          }
        }
      }

      print("Data consistency check completed");
    } catch (e) {
      print("Error during data consistency check: $e");
    }
  }

  // Clean all auth data
  static Future<void> _cleanAllAuthData(SharedPreferences prefs) async {
    try {
      // Clear auth tokens
      await prefs.remove('auth_token');
      await prefs.remove('basic_auth');
      await prefs.setBool('is_local_user', false);
      await prefs.remove('local_user_password');

      print("Cleaned all auth data");
    } catch (e) {
      print("Error cleaning auth data: $e");
    }
  }

  // Clean all user data
}
