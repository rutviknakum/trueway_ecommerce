// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  String? _authToken;

  // Initialize with auth check
  Future<void> init() async {
    await _loadAuthToken();
  }

  // Load the auth token from storage
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Helper method to clear all user data - helps prevent data leakage
  Future<void> _clearAllUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

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

      // Clear cached auth token
      _authToken = null;

      print("Cleared all user data");
    } catch (e) {
      print("Error clearing user data: $e");
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> loginWithServer(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      return {"success": false, "error": "Email and password are required"};
    }

    try {
      print(
        "Attempting login with email: $email, password length: ${password.length}",
      );

      // JWT authentication with email as username
      final jwtUrl = Uri.parse(ApiConfig.baseUrl + ApiConfig.authEndpoint);

      final jwtResponse = await http.post(
        jwtUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": email, "password": password},
      );

      print("JWT Auth response status: ${jwtResponse.statusCode}");

      // If JWT auth succeeded
      if (jwtResponse.statusCode == 200) {
        final authData = json.decode(jwtResponse.body);

        // Store the auth token and user info
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", authData['token']);
        _authToken = authData['token']; // Also set in memory
        await prefs.setString("user_email", email);

        String name = authData['user_display_name'] ?? "";
        await prefs.setString("user_name", name);

        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
          await prefs.setInt("user_id", userId);
          await prefs.setString("current_user_id", userId.toString());
        }

        // Try to get WooCommerce customer ID
        try {
          final customerId = await getCustomerId(email);
          if (customerId != null) {
            await prefs.setInt("customer_id", customerId);
          }
        } catch (e) {
          print("Error getting customer details: $e");
        }

        return {
          "success": true,
          "email": email,
          "name": name,
          "message": "Logged in successfully",
        };
      }

      // Try alternative login methods if JWT fails
      return await _handleFailedLogin(email, password, jwtResponse);
    } catch (e) {
      print("Login exception: $e");
      return {
        "success": false,
        "error": "Login failed. Please check your connection and try again.",
        "debug_info": "Exception: $e",
      };
    }
  }

  Future<Map<String, dynamic>> signupBasic(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        mobile.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return {"success": false, "error": "All fields are required"};
    }

    try {
      // Clear any previous user data to prevent data leakage
      await _clearAllUserData();

      // First check if the email already exists by trying to log in
      final loginResult = await loginWithServer(email, password);

      // If login succeeds, it means the account already exists
      if (loginResult['success']) {
        // Update the user data with the provided information
        final fullName = "$firstName $lastName";
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_name", fullName);
        await prefs.setString("user_first_name", firstName);
        await prefs.setString("user_last_name", lastName);
        await prefs.setString("user_phone", mobile);
        await prefs.setString("user_email", email); // Ensure email is set

        return {
          "success": true,
          "message": "Logged in successfully",
          "email": email,
          "name": fullName,
        };
      }

      // If we reach here, we need to implement a local-first registration approach
      print("Implementing local registration workaround");

      // Store the user data locally in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Generate a unique user ID based on the email
      final userId = email.hashCode.toString();
      final fullName = "$firstName $lastName";

      // Save all user data
      await prefs.setString("user_email", email);
      await prefs.setString("user_name", fullName);
      await prefs.setString("user_first_name", firstName);
      await prefs.setString("user_last_name", lastName);
      await prefs.setString("user_phone", mobile);
      await prefs.setString("user_id", userId);
      await prefs.setString("current_user_id", userId);

      // Store the password securely (you may want to use Flutter Secure Storage for this in production)
      await prefs.setString("local_user_password", password);

      // Set a flag indicating this is a locally registered user
      await prefs.setBool("is_local_user", true);

      // Mark the user as logged in
      _authToken = "local_auth_$userId"; // Pseudo token
      await prefs.setString("auth_token", _authToken!);

      print("Local registration successful: $userId - $fullName");

      // Also make an attempt to register on the server, but don't wait for the result
      _attemptServerRegistration(
        firstName,
        lastName,
        mobile,
        email,
        password,
      ).then((result) {
        print("Server registration attempt result: $result");
      });

      return {
        "success": true,
        "message": "Account created successfully",
        "email": email,
        "name": fullName,
        "local_only": true,
      };
    } catch (e) {
      print("Signup exception: $e");
      return {
        "success": false,
        "error": "Registration failed. Please check your connection.",
        "debug_info": "Exception: $e",
      };
    }
  }

  // Attempt server registration in the background
  Future<bool> _attemptServerRegistration(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
    try {
      // Try multiple registration approaches

      // 1. WordPress REST API
      try {
        final wpUrl = Uri.parse(
          "${ApiConfig.baseUrl}/wp-json/wp/v2/users/register",
        );
        final wpPayload = {
          "username": email,
          "email": email,
          "password": password,
          "first_name": firstName,
          "last_name": lastName,
        };

        final wpResponse = await http.post(
          wpUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(wpPayload),
        );

        if (wpResponse.statusCode >= 200 && wpResponse.statusCode < 300) {
          print("Server registration succeeded via WordPress API");
          return true;
        }
      } catch (e) {
        print("WordPress registration attempt failed: $e");
      }

      // 2. Custom registration endpoint (many WordPress sites have this)
      try {
        final customUrl = Uri.parse(
          "${ApiConfig.baseUrl}/wp-json/custom/v1/register",
        );
        final customPayload = {
          "username": email,
          "email": email,
          "password": password,
          "first_name": firstName,
          "last_name": lastName,
          "phone": mobile,
        };

        final customResponse = await http.post(
          customUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(customPayload),
        );

        if (customResponse.statusCode >= 200 &&
            customResponse.statusCode < 300) {
          print("Server registration succeeded via custom endpoint");
          return true;
        }
      } catch (e) {
        print("Custom endpoint registration attempt failed: $e");
      }

      // 3. WooCommerce API - last resort, but still try
      try {
        final customerUrl = Uri.parse(
          "${ApiConfig.baseUrl}${ApiConfig.customersEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}",
        );

        final wooPayload = {
          "email": email,
          "first_name": firstName,
          "last_name": lastName,
          "username": email,
          "password": password,
          "billing": {
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "phone": mobile,
            "address_1": "Default Address",
            "city": "Default City",
            "state": "State",
            "postcode": "000000",
            "country": "IN",
          },
          "shipping": {
            "first_name": firstName,
            "last_name": lastName,
            "address_1": "Default Address",
            "city": "Default City",
            "state": "State",
            "postcode": "000000",
            "country": "IN",
          },
        };

        // Try multiple postcode formats
        for (final postcode in ["000000", "123456", "400001", "", "      "]) {
          try {
            (wooPayload["billing"] as Map<String, dynamic>)["postcode"] =
                postcode;
            (wooPayload["shipping"] as Map<String, dynamic>)["postcode"] =
                postcode;

            final wooResponse = await http.post(
              customerUrl,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(wooPayload),
            );

            if (wooResponse.statusCode == 201) {
              print(
                "Server registration succeeded via WooCommerce API with postcode: $postcode",
              );
              return true;
            }
          } catch (e) {
            print(
              "WooCommerce registration attempt failed with postcode $postcode: $e",
            );
          }
        }
      } catch (e) {
        print("All WooCommerce registration attempts failed: $e");
      }

      return false;
    } catch (e) {
      print("All server registration attempts failed: $e");
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // First check if there's a standard auth token
    if (_authToken != null) return true;

    // Check for standard authentication
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    if (token != null) {
      _authToken = token; // Cache it in memory
      return true;
    }

    if (basicAuth != null) {
      return true;
    }

    // Check for local authentication
    final isLocalUser = prefs.getBool("is_local_user") ?? false;
    final userId = prefs.getString("user_id");
    final userEmail = prefs.getString("user_email");

    if (isLocalUser && userId != null && userEmail != null) {
      // Generate a pseudo token if needed
      if (_authToken == null) {
        _authToken = "local_auth_$userId";
        await prefs.setString("auth_token", _authToken!);
      }
      return true;
    }

    return false;
  }

  // Enhanced login method to handle local auth and prevent data leakage
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {"success": false, "error": "Email and password are required"};
    }

    try {
      // Clear any existing user data before attempting login
      // This prevents data leakage between users
      await _clearAllUserData();

      // First try to log in with server authentication
      print(
        "Attempting login with email: $email, password length: ${password.length}",
      );

      // Try JWT authentication
      final jwtUrl = Uri.parse(ApiConfig.baseUrl + ApiConfig.authEndpoint);
      final jwtResponse = await http.post(
        jwtUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": email, "password": password},
      );

      print("JWT Auth response status: ${jwtResponse.statusCode}");

      // If JWT auth succeeded
      if (jwtResponse.statusCode == 200) {
        final authData = json.decode(jwtResponse.body);

        // Store the auth token and user info
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", authData['token']);
        _authToken = authData['token']; // Also set in memory
        await prefs.setString("user_email", email);

        String name = authData['user_display_name'] ?? "";
        await prefs.setString("user_name", name);

        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
          await prefs.setInt("user_id", userId);
          await prefs.setString("current_user_id", userId.toString());
        }

        // Remove local user flag if it exists
        await prefs.setBool("is_local_user", false);

        // Try to get WooCommerce customer ID
        try {
          final customerId = await getCustomerId(email);
          if (customerId != null) {
            await prefs.setInt("customer_id", customerId);
          }
        } catch (e) {
          print("Error getting customer details: $e");
        }

        return {
          "success": true,
          "email": email,
          "name": name,
          "message": "Logged in successfully",
        };
      }

      // Try alternative login methods
      final alternativeResult = await _handleFailedLogin(
        email,
        password,
        jwtResponse,
      );
      if (alternativeResult["success"]) {
        return alternativeResult;
      }

      // If we reach here, try local authentication
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final isLocalUser = prefs.getBool("is_local_user") ?? false;
      final storedEmail = prefs.getString("user_email");
      final storedPassword = prefs.getString("local_user_password");

      if (isLocalUser && storedEmail == email && storedPassword == password) {
        // Local login successful
        final userId = prefs.getString("user_id") ?? email.hashCode.toString();
        final userName = prefs.getString("user_name") ?? email.split('@')[0];

        // Generate a pseudo token
        _authToken = "local_auth_$userId";
        await prefs.setString("auth_token", _authToken!);
        await prefs.setString("current_user_id", userId);

        // Ensure email is set correctly
        await prefs.setString("user_email", email);

        print("Local login successful: $userId - $userName");

        return {
          "success": true,
          "email": email,
          "name": userName,
          "message": "Logged in successfully (local mode)",
          "local_only": true,
        };
      }

      // All login methods failed
      return {
        "success": false,
        "error": "Login failed. Please check your credentials.",
        "account_exists": false,
      };
    } catch (e) {
      print("Login exception: $e");
      return {
        "success": false,
        "error": "Login failed. Please check your connection and try again.",
        "debug_info": "Exception: $e",
      };
    }
  }

  // Improved logout method
  Future<Map<String, dynamic>> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Store the current user ID before clearing data
      final currentUserId = prefs.getString('current_user_id');

      // Clear all user-specific data
      if (currentUserId != null) {
        // Clear prefixed user data
        for (String key in prefs.getKeys().where(
          (k) => k.startsWith('user_${currentUserId}_'),
        )) {
          await prefs.remove(key);
        }
      }

      // Clear general user data
      await prefs.remove("user_email");
      await prefs.remove("customer_id");
      await prefs.remove("user_id");
      await prefs.remove("user_name");
      await prefs.remove("user_phone");
      await prefs.remove("user_first_name");
      await prefs.remove("user_last_name");
      await prefs.remove("user_address");
      await prefs.remove("auth_token");
      await prefs.remove("basic_auth");
      await prefs.remove("current_user_id");
      await prefs.remove("is_local_user");
      await prefs.remove("local_user_password");

      // Clear any cached data
      _authToken = null;

      print("User logged out successfully - all data cleared");

      return {"success": true, "message": "Logged out successfully"};
    } catch (e) {
      print("Error during logout: $e");
      return {"success": false, "error": "Failed to log out: $e"};
    }
  }

  // Backwards compatibility method
  Future<bool> checkIfLoggedIn() async {
    return isLoggedIn();
  }

  // Improved getCurrentUser method
  Future<Map<String, dynamic>> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    final customerId = prefs.getInt("customer_id");
    final userId =
        prefs.getString("user_id") ?? prefs.getInt("user_id")?.toString();
    final name = prefs.getString("user_name");
    final phone = prefs.getString("user_phone");
    final firstName = prefs.getString("user_first_name");
    final lastName = prefs.getString("user_last_name");
    final isLocalUser = prefs.getBool("is_local_user") ?? false;
    final currentUserId = prefs.getString("current_user_id");

    // Check memory first, then shared preferences
    final token = _authToken ?? prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    // Verify we have a consistent user ID
    if (userId != null && currentUserId != null && userId != currentUserId) {
      print("Warning: User ID mismatch detected. Fixing...");
      await prefs.setString("current_user_id", userId);
    }

    final isLoggedIn =
        (token != null ||
            basicAuth != null ||
            (isLocalUser && userId != null)) &&
        email != null;

    if (isLoggedIn) {
      final userData = {
        "logged_in": true,
        "email": email,
        "customer_id": customerId,
        "user_id": userId,
        "name": name ?? "",
        "auth_type": isLocalUser ? "local" : (token != null ? "jwt" : "basic"),
        "local_only": isLocalUser,
      };

      // Add phone, first_name, and last_name if available
      if (phone != null) {
        userData["phone"] = phone;
      }

      if (firstName != null) {
        userData["first_name"] = firstName;
      }

      if (lastName != null) {
        userData["last_name"] = lastName;
      }

      return userData;
    }

    return {"logged_in": false};
  }

  // Backwards compatibility method
  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    return getCurrentUser();
  }

  Future<Map<String, dynamic>> _handleFailedLogin(
    String email,
    String password,
    http.Response jwtResponse,
  ) async {
    // Try username-based authentication if email looks like an email
    if (email.contains('@')) {
      final usernameGuess = email.split('@')[0];
      final result = await _tryUsernameLogin(usernameGuess, password);
      if (result["success"]) return result;
    }

    // Try basic authentication as a fallback
    final basicAuthResult = await _tryBasicAuth(email, password);
    if (basicAuthResult["success"]) return basicAuthResult;

    // Check if the customer exists but couldn't authenticate
    final customerExists = await checkEmailExists(email);
    if (customerExists) {
      return {
        "success": false,
        "error": "Authentication failed. Please check your password.",
        "account_exists": true,
      };
    }

    // Parse JWT error for a better message
    try {
      final errorData = json.decode(jwtResponse.body);
      if (errorData['message'] != null) {
        final cleanMessage = errorData['message']
            .replaceAll('<strong>', '')
            .replaceAll('</strong>', '')
            .replaceAll('<br />', ' ');

        if (errorData['code'] == '[jwt_auth] invalid_email' ||
            errorData['code'] == '[jwt_auth] invalid_username') {
          return {
            "success": false,
            "error": "Account not found. Please sign up for a new account.",
            "account_exists": false,
          };
        } else if (errorData['code'] == '[jwt_auth] incorrect_password') {
          return {
            "success": false,
            "error": "Incorrect password. Please try again.",
            "account_exists": true,
          };
        } else {
          return {"success": false, "error": cleanMessage};
        }
      }
    } catch (e) {
      print("Error parsing JWT response: $e");
    }

    return {
      "success": false,
      "error": "Login failed. Please check your credentials.",
      "account_exists": false,
    };
  }

  Future<Map<String, dynamic>> _tryUsernameLogin(
    String username,
    String password,
  ) async {
    try {
      print("Trying login with username: $username");
      final jwtUrl = Uri.parse(ApiConfig.baseUrl + ApiConfig.authEndpoint);

      final response = await http.post(
        jwtUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final authData = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", authData['token']);
        _authToken = authData['token']; // Also set in memory
        await prefs.setString("user_email", authData['user_email'] ?? "");
        await prefs.setString("user_name", authData['user_display_name'] ?? "");

        if (authData['user_id'] != null) {
          await prefs.setInt("user_id", authData['user_id']);
          await prefs.setString(
            "current_user_id",
            authData['user_id'].toString(),
          );
        }

        return {
          "success": true,
          "email": authData['user_email'] ?? "",
          "name": authData['user_display_name'] ?? "",
          "message": "Logged in successfully with username",
        };
      }
      return {"success": false};
    } catch (e) {
      print("Username login error: $e");
      return {"success": false};
    }
  }

  Future<Map<String, dynamic>> _tryBasicAuth(
    String email,
    String password,
  ) async {
    try {
      print("Trying basic auth");
      final basicCredentials = base64.encode(utf8.encode('$email:$password'));
      final basicAuthHeader = 'Basic $basicCredentials';

      final basicAuthUrl = Uri.parse("${ApiConfig.baseUrl}/wp/v2/users/me");
      final response = await http.get(
        basicAuthUrl,
        headers: {"Authorization": basicAuthHeader},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_email", email);
        await prefs.setString("basic_auth", basicAuthHeader);
        await prefs.setString("user_name", userData['name'] ?? "");

        if (userData['id'] != null) {
          await prefs.setInt("user_id", userData['id']);
          await prefs.setString("current_user_id", userData['id'].toString());
        }

        return {
          "success": true,
          "email": email,
          "name": userData['name'] ?? "",
          "message": "Logged in successfully with basic auth",
        };
      }
      return {"success": false};
    } catch (e) {
      print("Basic auth error: $e");
      return {"success": false};
    }
  }

  // Helper method to update the current user data in SharedPreferences
  Future<void> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');

      // Ensure we have a user ID to associate the data with
      if (currentUserId == null) {
        print(
          "Warning: No current user ID found, data may not be properly associated",
        );
      }

      if (userData.containsKey('name') && userData['name'] != null) {
        await prefs.setString("user_name", userData['name']);
        if (currentUserId != null) {
          await prefs.setString("user_${currentUserId}_name", userData['name']);
        }
      }

      if (userData.containsKey('email') && userData['email'] != null) {
        await prefs.setString("user_email", userData['email']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_email",
            userData['email'],
          );
        }
      }

      // Store other user data as needed
      if (userData.containsKey('phone') && userData['phone'] != null) {
        await prefs.setString("user_phone", userData['phone']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_phone",
            userData['phone'],
          );
        }
      }

      if (userData.containsKey('address') && userData['address'] != null) {
        await prefs.setString("user_address", userData['address']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_address",
            userData['address'],
          );
        }
      }

      if (userData.containsKey('first_name') &&
          userData['first_name'] != null) {
        await prefs.setString("user_first_name", userData['first_name']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_first_name",
            userData['first_name'],
          );
        }
      }

      if (userData.containsKey('last_name') && userData['last_name'] != null) {
        await prefs.setString("user_last_name", userData['last_name']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_last_name",
            userData['last_name'],
          );
        }
      }
    } catch (e) {
      print("Error updating current user data: $e");
      throw e;
    }
  }

  // Helper methods
  Future<bool> checkEmailExists(String email) async {
    try {
      final url = Uri.parse(
        ApiConfig.buildUrl(
          ApiConfig.customersEndpoint,
          queryParams: {"email": email},
        ),
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List customers = json.decode(response.body);
        return customers.isNotEmpty;
      }
      return false;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  Future<int?> getCustomerId(String email) async {
    try {
      final url = Uri.parse(
        ApiConfig.buildUrl(
          ApiConfig.customersEndpoint,
          queryParams: {"email": email},
        ),
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List customers = json.decode(response.body);
        if (customers.isNotEmpty) {
          return customers[0]["id"];
        }
      }
      return null;
    } catch (e) {
      print("Error getting customer ID: $e");
      return null;
    }
  }

  // API request methods
  Future<Map<String, String>> getAuthHeaders({
    bool includeWooAuth = false,
  }) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
    };

    try {
      // Use cached auth token if available, otherwise load from SharedPreferences
      if (_authToken == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString("auth_token");
      }

      final basicAuth = await _getBasicAuth();

      if (_authToken != null) {
        headers["Authorization"] = "Bearer $_authToken";
      } else if (basicAuth != null) {
        headers["Authorization"] = basicAuth;
      }

      // For WooCommerce API requests that require consumer key/secret
      if (includeWooAuth) {
        final String consumerKey = ApiConfig.consumerKey;
        final String consumerSecret = ApiConfig.consumerSecret;

        if (consumerKey.isNotEmpty && consumerSecret.isNotEmpty) {
          // Override existing Authorization with WooCommerce credentials
          String credentials = base64Encode(
            utf8.encode('$consumerKey:$consumerSecret'),
          );
          headers['Authorization'] = 'Basic $credentials';

          // Debug
          print("Using WooCommerce API authentication");
        } else {
          print("Warning: WooCommerce API credentials not found");
        }
      }

      return headers;
    } catch (e) {
      print("Error getting auth headers: $e");
      return headers;
    }
  }

  // Helper method to get basic auth from SharedPreferences
  Future<String?> _getBasicAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("basic_auth");
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    try {
      // Check if user is logged in
      bool isLoggedIn = await this.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Get customer ID and user ID (ensure they're strings)
      final customerId = userData['customer_id']?.toString();
      final userId = userData['user_id']?.toString();

      // Store updated data in SharedPreferences for local access
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');

      if (userData['name'] != null) {
        await prefs.setString("user_name", userData['name']);
        if (currentUserId != null) {
          await prefs.setString("user_${currentUserId}_name", userData['name']);
        }
      }

      if (userData['phone'] != null) {
        await prefs.setString("user_phone", userData['phone']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_phone",
            userData['phone'],
          );
        }
      }

      if (userData['address'] != null) {
        await prefs.setString("user_address", userData['address']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_address",
            userData['address'],
          );
        }
      }

      if (userData['first_name'] != null) {
        await prefs.setString("user_first_name", userData['first_name']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_first_name",
            userData['first_name'],
          );
        }
      }

      if (userData['last_name'] != null) {
        await prefs.setString("user_last_name", userData['last_name']);
        if (currentUserId != null) {
          await prefs.setString(
            "user_${currentUserId}_last_name",
            userData['last_name'],
          );
        }
      }

      // If we have a customer ID, update WooCommerce customer data
      if (customerId != null) {
        try {
          // Use the correct WooCommerce v3 API endpoint with proper formatting
          final url = Uri.parse(
            ApiConfig.buildUrl("${ApiConfig.customersEndpoint}/$customerId"),
          );

          // Parse address into components if available
          Map<String, String> addressComponents = {};
          if (userData['address'] != null &&
              userData['address'].toString().isNotEmpty) {
            addressComponents = _parseAddressString(userData['address']);
          }

          // Extract first and last name from full name if not provided directly
          String firstName = userData['first_name'] ?? '';
          String lastName = userData['last_name'] ?? '';

          // If first/last name not provided but full name is available
          if ((firstName.isEmpty || lastName.isEmpty) &&
              userData['name'] != null) {
            String fullName = userData['name'] ?? '';
            if (fullName.contains(' ')) {
              final nameParts = fullName.split(' ');
              if (firstName.isEmpty) firstName = nameParts.first;
              if (lastName.isEmpty) lastName = nameParts.sublist(1).join(' ');
            } else if (firstName.isEmpty) {
              firstName = fullName;
            }
          }

          // Create properly structured update payload
          final Map<String, dynamic> updateData = {
            'first_name': firstName,
            'last_name': lastName,
            'billing': {
              'first_name': firstName,
              'last_name': lastName,
              'phone': userData['phone'] ?? '',
              'email': userData['email'] ?? '', // Include email in billing
            },
            'shipping': {'first_name': firstName, 'last_name': lastName},
          };

          // Add address components if available
          if (addressComponents.isNotEmpty) {
            updateData['billing']['address_1'] =
                addressComponents['street'] ?? '';
            updateData['billing']['city'] = addressComponents['city'] ?? '';
            updateData['billing']['state'] = addressComponents['state'] ?? '';
            updateData['billing']['postcode'] =
                addressComponents['postalCode'] ?? '123456'; // Default postcode
            updateData['billing']['country'] =
                addressComponents['country'] ?? 'IN'; // Default country

            // Also update shipping address
            updateData['shipping']['address_1'] =
                addressComponents['street'] ?? '';
            updateData['shipping']['city'] = addressComponents['city'] ?? '';
            updateData['shipping']['state'] = addressComponents['state'] ?? '';
            updateData['shipping']['postcode'] =
                addressComponents['postalCode'] ?? '123456'; // Default postcode
            updateData['shipping']['country'] =
                addressComponents['country'] ?? 'IN'; // Default country
          } else {
            // Add default values if no address components
            updateData['billing']['address_1'] = 'Default Address';
            updateData['billing']['city'] = 'Default City';
            updateData['billing']['state'] = 'Default State';
            updateData['billing']['postcode'] = '123456';
            updateData['billing']['country'] = 'IN';

            updateData['shipping']['address_1'] = 'Default Address';
            updateData['shipping']['city'] = 'Default City';
            updateData['shipping']['state'] = 'Default State';
            updateData['shipping']['postcode'] = '123456';
            updateData['shipping']['country'] = 'IN';
          }

          // Get auth headers with proper WooCommerce API authentication
          final headers = await getAuthHeaders(includeWooAuth: true);

          // Debug the request
          print("Updating customer with URL: $url");
          print("Headers: $headers");
          print("Update data: ${json.encode(updateData)}");

          // Send update request to WooCommerce API
          final response = await http.put(
            url,
            headers: headers,
            body: json.encode(updateData),
          );

          if (response.statusCode == 200) {
            print("Customer profile updated successfully");
            return {'success': true, 'message': 'Profile updated successfully'};
          } else {
            print("Failed to update customer: ${response.statusCode}");
            print("Response body: ${response.body}");

            // If we got a 403, try the WordPress user update method as fallback
            if (response.statusCode == 403 && userId != null) {
              print("Falling back to WordPress user update");
              return await _updateWordPressUser(userId, userData);
            }

            // If WooCommerce update fails, still return success since we've updated local data
            return {
              'success': true,
              'message':
                  'Profile updated locally. Some changes may not sync with server.',
            };
          }
        } catch (e) {
          print("Error updating customer profile: $e");
          // Continue even if API update fails - we've already saved locally
          return {
            'success': true,
            'message': 'Profile updated locally. Server sync failed.',
          };
        }
      }
      // If no customer ID but we have a WordPress user ID
      else if (userId != null) {
        return await _updateWordPressUser(userId, userData);
      }

      // If no customer ID or user ID, just return success for local update
      return {'success': true, 'message': 'Profile updated locally'};
    } catch (e) {
      print('Error in updateUserProfile: $e');
      return {
        'success': false,
        'error': 'An error occurred while updating profile',
      };
    }
  }

  // Helper method to update WordPress user data
  Future<Map<String, dynamic>> _updateWordPressUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final headers = await getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final url = Uri.parse('${ApiConfig.baseUrl}/wp/v2/users/$userId');

      // Extract name components
      String firstName = userData['first_name'] ?? '';
      String lastName = userData['last_name'] ?? '';
      String fullName = userData['name'] ?? '';

      if (fullName.isEmpty && firstName.isNotEmpty) {
        fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
      }

      // Create update payload
      final Map<String, dynamic> updateData = {
        'name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'meta': {
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? '',
        },
      };

      // Send update request to WordPress API
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        print("WordPress user profile updated successfully");
        return {'success': true, 'message': 'Profile updated successfully'};
      } else {
        print("Failed to update WordPress user: ${response.statusCode}");
        print("Response body: ${response.body}");

        // If WordPress update fails, still return success since we've updated local data
        return {
          'success': true,
          'message':
              'Profile updated locally. Some changes may not sync with server.',
        };
      }
    } catch (e) {
      print("Error updating WordPress user profile: $e");
      // Continue even if API update fails - we've already saved locally
      return {
        'success': true,
        'message': 'Profile updated locally. Server sync failed.',
      };
    }
  }

  // Helper method to parse address string into components
  Map<String, String> _parseAddressString(String address) {
    Map<String, String> result = {
      'street': '',
      'city': '',
      'state': '',
      'postalCode': '',
      'country': '',
    };

    if (address.isEmpty) return result;

    List<String> parts = address.split(', ');

    if (parts.length >= 1) result['street'] = parts[0];
    if (parts.length >= 2) result['city'] = parts[1];
    if (parts.length >= 3) result['state'] = parts[2];
    if (parts.length >= 4) result['postalCode'] = parts[3];
    if (parts.length >= 5) result['country'] = parts[4];

    return result;
  }

  // Enhanced authenticated request method with WooCommerce auth handling
  Future<http.Response> authenticatedRequest(
    String endpoint, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParams,
    int timeoutSeconds = 30,
  }) async {
    // Check auth status
    final isAuth = await isLoggedIn();
    if (!isAuth) {
      throw Exception("Not authenticated");
    }

    // Determine if this is a WooCommerce API endpoint
    bool isWooCommerceEndpoint =
        endpoint.contains('/wc/v3/') ||
        endpoint.startsWith(ApiConfig.ordersEndpoint) ||
        endpoint.startsWith(ApiConfig.productsEndpoint) ||
        endpoint.startsWith(ApiConfig.customersEndpoint);

    // Get appropriate auth headers
    Map<String, String> headers = await getAuthHeaders(
      includeWooAuth: isWooCommerceEndpoint,
    );

    // Add customer ID to query if applicable
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    // Build URL with customer ID if applicable
    String urlString =
        queryParams != null
            ? ApiConfig.buildUrl(endpoint, queryParams: queryParams)
            : ApiConfig.buildUrl(endpoint);

    if (customerId != null &&
        !endpoint.contains("customer=") &&
        !endpoint.contains("/customers/") &&
        method.toUpperCase() == 'GET') {
      String separator = urlString.contains("?") ? "&" : "?";
      urlString = "$urlString${separator}customer=$customerId";
    }

    final url = Uri.parse(urlString);

    // Add debug information
    print("Sending ${method.toUpperCase()} request to: $url");
    print("Headers: $headers");
    if (body != null) {
      print("Request body: ${body is String ? body : json.encode(body)}");
    }

    try {
      // Create a client with timeout
      final client = http.Client();

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await client
              .get(url, headers: headers)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'POST':
          response = await client
              .post(
                url,
                headers: headers,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'PUT':
          response = await client
              .put(
                url,
                headers: headers,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'DELETE':
          response = await client
              .delete(url, headers: headers)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        default:
          client.close();
          throw Exception("Unsupported HTTP method: $method");
      }

      // Always close the client
      client.close();

      // Debug response
      print("Response status: ${response.statusCode}");
      if (response.statusCode >= 400) {
        print("Error response body: ${response.body}");

        // Special handling for WooCommerce endpoints with permission issues
        if (response.statusCode == 403 && isWooCommerceEndpoint) {
          print(
            "WooCommerce permission error. Retrying with alternative authentication...",
          );

          // For development purposes - simulate success if configured
          if (ApiConfig.useSimulatedOrderResponse &&
              endpoint.contains('/orders') &&
              method.toUpperCase() == 'POST') {
            print("Using simulated order response");
            return http.Response(
              jsonEncode({
                "id": DateTime.now().millisecondsSinceEpoch,
                "number":
                    "SIM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
                "status": "pending",
                "created_at": DateTime.now().toIso8601String(),
              }),
              201,
              headers: {"content-type": "application/json"},
            );
          }

          // Try a different authentication approach - fallback to query parameters
          if (ApiConfig.consumerKey.isNotEmpty &&
              ApiConfig.consumerSecret.isNotEmpty) {
            // Remove Authorization header and use query params instead
            headers.remove('Authorization');

            // Add consumer key and secret to URL
            String separator = url.toString().contains("?") ? "&" : "?";
            final newUrl = Uri.parse(
              "${url}${separator}consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}",
            );

            print("Retrying with query parameter authentication: $newUrl");

            // Make the request again
            switch (method.toUpperCase()) {
              case 'GET':
                return await client
                    .get(newUrl, headers: headers)
                    .timeout(Duration(seconds: timeoutSeconds));
              case 'POST':
                return await client
                    .post(
                      newUrl,
                      headers: headers,
                      body: body is String ? body : json.encode(body),
                    )
                    .timeout(Duration(seconds: timeoutSeconds));
              case 'PUT':
                return await client
                    .put(
                      newUrl,
                      headers: headers,
                      body: body is String ? body : json.encode(body),
                    )
                    .timeout(Duration(seconds: timeoutSeconds));
              case 'DELETE':
                return await client
                    .delete(newUrl, headers: headers)
                    .timeout(Duration(seconds: timeoutSeconds));
              default:
                throw Exception("Unsupported HTTP method: $method");
            }
          }
        }
      }

      return response;
    } catch (e) {
      print("Error in authenticated request: $e");
      rethrow;
    }
  }

  Future<http.Response> publicRequest(
    String endpoint, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    final url = Uri.parse(
      ApiConfig.buildUrl(endpoint, queryParams: queryParams),
    );

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url);
        case 'POST':
          Map<String, String> headers = {"Content-Type": "application/json"};
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          Map<String, String> headers = {"Content-Type": "application/json"};
          return await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return await http.delete(url);
        default:
          throw Exception("Unsupported HTTP method: $method");
      }
    } catch (e) {
      print("Error in public request: $e");
      rethrow;
    }
  }

  // Improved getUserProfile method with proper type handling
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (!await isLoggedIn()) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final userInfo = await getCurrentUser();

      // Get user ID - handle both string and int types properly
      dynamic userId = userInfo['user_id'];
      dynamic customerId = userInfo['customer_id'];

      if (userId == null && customerId == null) {
        return {
          'success': false,
          'error': 'No user ID or customer ID available',
        };
      }

      // Try to get customer data first if available
      if (customerId != null) {
        try {
          // Convert customerId to string to ensure it works properly in the URL
          final customerIdStr = customerId.toString();
          final url = Uri.parse(
            ApiConfig.buildUrl("${ApiConfig.customersEndpoint}/$customerIdStr"),
          );

          final headers = await getAuthHeaders(includeWooAuth: true);
          final response = await http.get(url, headers: headers);

          if (response.statusCode == 200) {
            final customerData = json.decode(response.body);
            return {'success': true, 'data': customerData};
          }
        } catch (e) {
          print("Error getting customer profile: $e");
        }
      }

      // Fallback to WordPress user data
      if (userId != null) {
        try {
          // Convert userId to string to ensure it works properly in the URL
          final userIdStr = userId.toString();
          final url = Uri.parse("${ApiConfig.baseUrl}/wp/v2/users/$userIdStr");
          final headers = await getAuthHeaders();
          final response = await http.get(url, headers: headers);

          if (response.statusCode == 200) {
            final userData = json.decode(response.body);
            return {'success': true, 'data': userData};
          }
        } catch (e) {
          print("Error getting WordPress user profile: $e");
        }
      }

      // If all else fails, return the current user data we have
      return {'success': true, 'data': userInfo};
    } catch (e) {
      print("Error in getUserProfile: $e");
      return {'success': false, 'error': 'Failed to get user profile: $e'};
    }
  }

  // Get orders for current user with proper handling
  // Improved getOrders method for proper handling of new users
  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int perPage = 10,
    String status = 'any',
  }) async {
    try {
      // Check login status
      final userInfo = await getCurrentUser();
      if (!userInfo["logged_in"]) {
        print("User not logged in, returning empty orders list");
        return [];
      }

      // Check if this is a local user
      final isLocalUser = userInfo["local_only"] == true;

      // For local users that haven't been synchronized with the server yet,
      // return an empty list instead of trying to fetch from server
      if (isLocalUser && userInfo["customer_id"] == null) {
        print("Local user without customer ID - returning empty orders list");
        return [];
      }

      // Build query parameters
      Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (status != 'any') {
        queryParams['status'] = status;
      }

      // If we have a customer ID, add it to the query
      if (userInfo["customer_id"] != null) {
        queryParams['customer'] = userInfo["customer_id"].toString();
      } else {
        // If we don't have a customer ID but have a user ID, try to use that
        if (userInfo["user_id"] != null) {
          // Some WooCommerce setups allow filtering by user ID instead of customer ID
          queryParams['user_id'] = userInfo["user_id"].toString();
        } else {
          // No customer ID or user ID - return empty list
          print(
            "No customer ID or user ID available - returning empty orders list",
          );
          return [];
        }
      }

      // Make request with WooCommerce authentication
      try {
        final response = await authenticatedRequest(
          ApiConfig.ordersEndpoint,
          method: 'GET',
          queryParams: queryParams,
          timeoutSeconds: 10, // Shorter timeout for better UX
        );

        if (response.statusCode == 200) {
          List<dynamic> orders = json.decode(response.body);
          return orders.cast<Map<String, dynamic>>();
        } else {
          print("Failed to fetch orders: ${response.statusCode}");
          // Return empty list on error rather than throwing exception
          return [];
        }
      } catch (requestError) {
        print("Error making orders request: $requestError");
        // Return empty list on error
        return [];
      }
    } catch (e) {
      print("Error in getOrders: $e");
      // Return empty list instead of throwing to provide better UX
      return [];
    }
  }

  // Get user's order count - useful for determining if user is new
  Future<int> getOrderCount() async {
    try {
      // Check login status
      final userInfo = await getCurrentUser();
      if (!userInfo["logged_in"]) {
        return 0;
      }

      // Check if this is a local user
      final isLocalUser = userInfo["local_only"] == true;

      // For local users, return 0 orders
      if (isLocalUser && userInfo["customer_id"] == null) {
        return 0;
      }

      // If we don't have a customer ID, return 0
      if (userInfo["customer_id"] == null) {
        return 0;
      }

      // Build query parameters - just get 1 order to check if any exist
      Map<String, dynamic> queryParams = {
        'page': '1',
        'per_page': '1',
        'customer': userInfo["customer_id"].toString(),
      };

      try {
        final response = await authenticatedRequest(
          ApiConfig.ordersEndpoint,
          method: 'GET',
          queryParams: queryParams,
        );

        if (response.statusCode == 200) {
          // Check if the total count is in the headers
          final totalCountHeader = response.headers['x-wp-total'];
          if (totalCountHeader != null) {
            return int.tryParse(totalCountHeader) ?? 0;
          }

          // If no header, at least check if array has items
          List<dynamic> orders = json.decode(response.body);
          return orders.isEmpty ? 0 : 1; // Return at least 1 if we got results
        } else {
          return 0;
        }
      } catch (e) {
        print("Error fetching order count: $e");
        return 0;
      }
    } catch (e) {
      print("Error in getOrderCount: $e");
      return 0;
    }
  }

  // Check if user is a new customer with no orders
  Future<bool> isNewCustomer() async {
    // First check if this is a local user
    final userInfo = await getCurrentUser();
    if (userInfo["local_only"] == true) {
      return true;
    }

    // Then check if they have any orders
    final orderCount = await getOrderCount();
    return orderCount == 0;
  }

  // Get single order by ID with proper handling
  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final response = await authenticatedRequest(
        "${ApiConfig.ordersEndpoint}/$orderId",
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch order #$orderId: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching order #$orderId: $e");
      return null;
    }
  }
}
