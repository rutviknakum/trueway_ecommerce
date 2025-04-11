// storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;
  bool _initialized = false;

  // Add an in-memory fallback user ID for when there is none available
  // This ensures we always have a user ID, even during initial app launch
  String _fallbackUserId = DateTime.now().millisecondsSinceEpoch.toString();

  // Constructor
  StorageService();

  // Initialize the shared preferences
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;

      // Check if we need to create a fallback user ID
      await _ensureUserIdExists();
    }
  }

  // Make sure we always have a user ID available
  Future<void> _ensureUserIdExists() async {
    final userId = await getUserId();
    final currentUserId = await getCurrentUserId();

    if (userId == null || currentUserId == null) {
      print(
        "No user ID found during initialization, creating fallback ID: $_fallbackUserId",
      );

      if (userId == null) {
        await setUserId(_fallbackUserId);
      }

      if (currentUserId == null) {
        await setCurrentUserId(_fallbackUserId);
      }
    }
  }

  // Helper method to ensure preferences are initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Helper method to clear all user data - helps prevent data leakage
  Future<void> clearAllUserData() async {
    try {
      final prefs = await _getPrefs();
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

      print("Cleared all user data");
    } catch (e) {
      print("Error clearing user data: $e");
    }
  }

  // Authentication token methods
  Future<String?> getAuthToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('auth_token');
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('auth_token', token);
  }

  // Basic auth methods
  Future<String?> getBasicAuth() async {
    final prefs = await _getPrefs();
    return prefs.getString('basic_auth');
  }

  Future<void> setBasicAuth(String basicAuth) async {
    final prefs = await _getPrefs();
    await prefs.setString('basic_auth', basicAuth);
  }

  // User data methods
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_email');
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_email', email);
  }

  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_name');
  }

  Future<void> setUserName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_name', name);
  }

  Future<String?> getUserFirstName() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_first_name');
  }

  Future<void> setUserFirstName(String firstName) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_first_name', firstName);
  }

  Future<String?> getUserLastName() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_last_name');
  }

  Future<void> setUserLastName(String lastName) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_last_name', lastName);
  }

  Future<String?> getUserPhone() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_phone');
  }

  Future<void> setUserPhone(String phone) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_phone', phone);
  }

  Future<String?> getUserAddress() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_address');
  }

  Future<void> setUserAddress(String address) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_address', address);
  }

  // User ID methods
  Future<String?> getUserId() async {
    try {
      final prefs = await _getPrefs();
      String? id =
          prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString();

      // If there's no stored user ID, return the fallback
      if (id == null || id.isEmpty) {
        return _fallbackUserId;
      }
      return id;
    } catch (e) {
      print("Error in getUserId: $e");
      return _fallbackUserId;
    }
  }

  Future<void> setUserId(dynamic userId) async {
    try {
      final prefs = await _getPrefs();
      if (userId is int) {
        await prefs.setInt('user_id', userId);
      } else {
        await prefs.setString('user_id', userId.toString());
      }
    } catch (e) {
      print("Error in setUserId: $e");
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await _getPrefs();
      String? id = prefs.getString('current_user_id');

      // If there's no current user ID, return the user ID or fallback
      if (id == null || id.isEmpty) {
        id = await getUserId();
      }
      return id;
    } catch (e) {
      print("Error in getCurrentUserId: $e");
      return _fallbackUserId;
    }
  }

  Future<void> setCurrentUserId(String userId) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString('current_user_id', userId);
    } catch (e) {
      print("Error in setCurrentUserId: $e");
    }
  }

  // Customer ID methods
  Future<int?> getCustomerId() async {
    final prefs = await _getPrefs();
    return prefs.getInt('customer_id');
  }

  Future<void> setCustomerId(int customerId) async {
    final prefs = await _getPrefs();
    await prefs.setInt('customer_id', customerId);
  }

  // Local user methods
  Future<bool> getIsLocalUser() async {
    final prefs = await _getPrefs();
    return prefs.getBool('is_local_user') ?? false;
  }

  Future<void> setIsLocalUser(bool isLocalUser) async {
    final prefs = await _getPrefs();
    await prefs.setBool('is_local_user', isLocalUser);
  }

  Future<String?> getLocalUserPassword() async {
    final prefs = await _getPrefs();
    return prefs.getString('local_user_password');
  }

  Future<void> setLocalUserPassword(String password) async {
    final prefs = await _getPrefs();
    await prefs.setString('local_user_password', password);
  }

  // User-specific data with prefix methods
  Future<void> setUserSpecificData(
    String userId,
    String key,
    String value,
  ) async {
    try {
      if (userId.isEmpty) {
        print("Error in setUserSpecificData: empty user ID provided");
        return;
      }
      final prefs = await _getPrefs();
      final keyName = 'user_${userId}_$key';
      print("Saving specific data: $keyName = $value");
      await prefs.setString(keyName, value);
    } catch (e) {
      print("Error in setUserSpecificData: $e");
    }
  }

  Future<String?> getUserSpecificData(String userId, String key) async {
    try {
      if (userId.isEmpty) {
        print("Error in getUserSpecificData: empty user ID provided");
        return null;
      }
      final prefs = await _getPrefs();
      return prefs.getString('user_${userId}_$key');
    } catch (e) {
      print("Error in getUserSpecificData: $e");
      return null;
    }
  }

  // Method to update all user data from a map
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      // IMPORTANT: Always get a user ID, even if we have to use the fallback
      String currentUserId = (await getCurrentUserId()) ?? _fallbackUserId;

      // If userData contains a user_id, prioritize that
      final dataUserId = userData['user_id']?.toString();
      if (dataUserId != null && dataUserId.isNotEmpty) {
        currentUserId = dataUserId;
        await setUserId(currentUserId);
        await setCurrentUserId(currentUserId);
      }

      // Now we should always have a user ID, so we can proceed without warning

      // Save all data to global keys
      if (userData.containsKey('name') && userData['name'] != null) {
        await setUserName(userData['name']);
        await setUserSpecificData(currentUserId, 'name', userData['name']);
      }

      if (userData.containsKey('email') && userData['email'] != null) {
        await setUserEmail(userData['email']);
        await setUserSpecificData(currentUserId, 'email', userData['email']);
      }

      if (userData.containsKey('phone') && userData['phone'] != null) {
        await setUserPhone(userData['phone']);
        await setUserSpecificData(currentUserId, 'phone', userData['phone']);
      }

      if (userData.containsKey('address') && userData['address'] != null) {
        await setUserAddress(userData['address']);
        await setUserSpecificData(
          currentUserId,
          'address',
          userData['address'],
        );
      }

      if (userData.containsKey('first_name') &&
          userData['first_name'] != null) {
        await setUserFirstName(userData['first_name']);
        await setUserSpecificData(
          currentUserId,
          'first_name',
          userData['first_name'],
        );
      }

      if (userData.containsKey('last_name') && userData['last_name'] != null) {
        await setUserLastName(userData['last_name']);
        await setUserSpecificData(
          currentUserId,
          'last_name',
          userData['last_name'],
        );
      }

      // If customer_id is in the data, make sure it's saved
      if (userData.containsKey('customer_id') &&
          userData['customer_id'] != null) {
        await setCustomerId(userData['customer_id']);
      }
    } catch (e) {
      print("Error in updateUserData: $e");
    }
  }
}
