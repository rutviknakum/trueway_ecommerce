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
    String? token = prefs.getString('auth_token');

    // Additional safety check to handle 'null' string value
    if (token == 'null' || token == '') {
      return null;
    }
    return token;
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('auth_token', token);
  }

  // Basic auth methods
  Future<String?> getBasicAuth() async {
    final prefs = await _getPrefs();
    String? auth = prefs.getString('basic_auth');

    // Additional safety check to handle 'null' string value
    if (auth == 'null' || auth == '') {
      return null;
    }
    return auth;
  }

  Future<void> setBasicAuth(String basicAuth) async {
    final prefs = await _getPrefs();
    await prefs.setString('basic_auth', basicAuth);
  }

  // User data methods
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    String? email = prefs.getString('user_email');

    // Additional check for empty or 'null' string
    if (email == null || email.isEmpty || email == 'null') {
      return null;
    }
    return email;
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_email', email);
  }

  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    String? name = prefs.getString('user_name');

    // Additional check for empty or 'null' string
    if (name == null || name.isEmpty || name == 'null') {
      return null;
    }
    return name;
  }

  Future<void> setUserName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_name', name);
  }

  Future<String?> getUserFirstName() async {
    final prefs = await _getPrefs();
    String? firstName = prefs.getString('user_first_name');

    // Additional check for empty or 'null' string
    if (firstName == null || firstName.isEmpty || firstName == 'null') {
      return null;
    }
    return firstName;
  }

  Future<void> setUserFirstName(String firstName) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_first_name', firstName);
  }

  Future<String?> getUserLastName() async {
    final prefs = await _getPrefs();
    String? lastName = prefs.getString('user_last_name');

    // Additional check for empty or 'null' string
    if (lastName == null || lastName.isEmpty || lastName == 'null') {
      return null;
    }
    return lastName;
  }

  Future<void> setUserLastName(String lastName) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_last_name', lastName);
  }

  Future<String?> getUserPhone() async {
    final prefs = await _getPrefs();
    String? phone = prefs.getString('user_phone');

    // Additional check for empty or 'null' string
    if (phone == null || phone.isEmpty || phone == 'null') {
      return null;
    }
    return phone;
  }

  Future<void> setUserPhone(String phone) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_phone', phone);
  }

  Future<String?> getUserAddress() async {
    final prefs = await _getPrefs();
    String? address = prefs.getString('user_address');

    // Additional check for empty or 'null' string
    if (address == null || address.isEmpty || address == 'null') {
      return null;
    }
    return address;
  }

  Future<void> setUserAddress(String address) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_address', address);
  }

  // User ID methods
  Future<String?> getUserId() async {
    try {
      final prefs = await _getPrefs();
      String? id = prefs.getString('user_id');

      // Try int value if string is null
      if (id == null) {
        int? intId = prefs.getInt('user_id');
        id = intId?.toString();
      }

      // Check for 'null' string or empty string
      if (id == null || id.isEmpty || id == 'null') {
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

      // Check for 'null' string or empty string
      if (id == null || id.isEmpty || id == 'null') {
        // If there's no current user ID, return the user ID or fallback
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
    int? id = prefs.getInt('customer_id');

    // Additional check for invalid values
    if (id == 0) {
      return null;
    }
    return id;
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
    String? password = prefs.getString('local_user_password');

    // Additional check for empty or 'null' string
    if (password == null || password.isEmpty || password == 'null') {
      return null;
    }
    return password;
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
      String? value = prefs.getString('user_${userId}_$key');

      // Check for 'null' string or empty string
      if (value == null || value.isEmpty || value == 'null') {
        return null;
      }
      return value;
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
      if (dataUserId != null && dataUserId.isNotEmpty && dataUserId != 'null') {
        currentUserId = dataUserId;
        await setUserId(currentUserId);
        await setCurrentUserId(currentUserId);
      }

      // Now we should always have a user ID, so we can proceed without warning

      // Save all data to global keys
      if (userData.containsKey('name') &&
          userData['name'] != null &&
          userData['name'] != 'null') {
        await setUserName(userData['name'].toString());
        await setUserSpecificData(
          currentUserId,
          'name',
          userData['name'].toString(),
        );
      }

      if (userData.containsKey('email') &&
          userData['email'] != null &&
          userData['email'] != 'null') {
        await setUserEmail(userData['email'].toString());
        await setUserSpecificData(
          currentUserId,
          'email',
          userData['email'].toString(),
        );
      }

      if (userData.containsKey('phone') &&
          userData['phone'] != null &&
          userData['phone'] != 'null') {
        await setUserPhone(userData['phone'].toString());
        await setUserSpecificData(
          currentUserId,
          'phone',
          userData['phone'].toString(),
        );
      }

      if (userData.containsKey('address') &&
          userData['address'] != null &&
          userData['address'] != 'null') {
        await setUserAddress(userData['address'].toString());
        await setUserSpecificData(
          currentUserId,
          'address',
          userData['address'].toString(),
        );
      }

      if (userData.containsKey('first_name') &&
          userData['first_name'] != null &&
          userData['first_name'] != 'null') {
        await setUserFirstName(userData['first_name'].toString());
        await setUserSpecificData(
          currentUserId,
          'first_name',
          userData['first_name'].toString(),
        );
      }

      if (userData.containsKey('last_name') &&
          userData['last_name'] != null &&
          userData['last_name'] != 'null') {
        await setUserLastName(userData['last_name'].toString());
        await setUserSpecificData(
          currentUserId,
          'last_name',
          userData['last_name'].toString(),
        );
      }

      // If customer_id is in the data, make sure it's saved
      if (userData.containsKey('customer_id') &&
          userData['customer_id'] != null) {
        int? customerId;

        if (userData['customer_id'] is int) {
          customerId = userData['customer_id'];
        } else if (userData['customer_id'] is String) {
          customerId = int.tryParse(userData['customer_id']);
        }

        if (customerId != null && customerId > 0) {
          await setCustomerId(customerId);
        }
      }

      // If auth_type is in the data, update local user status
      if (userData.containsKey('auth_type') && userData['auth_type'] != null) {
        bool isLocal = userData['auth_type'].toString() == 'local';
        await setIsLocalUser(isLocal);
      }

      // Directly handle local_only flag if present
      if (userData.containsKey('local_only') &&
          userData['local_only'] != null) {
        bool isLocal = userData['local_only'] == true;
        await setIsLocalUser(isLocal);
      }
    } catch (e) {
      print("Error in updateUserData: $e");
    }
  }
}
