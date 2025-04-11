// auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';
import 'api_client.dart';

class AuthService {
  final StorageService _storage;
  String? _authToken;
  final ApiClient _apiClient = ApiClient();

  AuthService(this._storage);

  Future<void> _loadAuthToken() async {
    _authToken = await _storage.getAuthToken();
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
        await _storage.setAuthToken(authData['token']);
        _authToken = authData['token']; // Also set in memory
        await _storage.setUserEmail(email);

        String name = authData['user_display_name'] ?? "";
        await _storage.setUserName(name);

        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
          await _storage.setUserId(userId);
          await _storage.setCurrentUserId(userId.toString());

          // Store the entire user data in one go
          final userData = {
            "user_id": userId,
            "email": email,
            "name": name,
            "auth_type": "jwt",
          };
          await _storage.updateUserData(userData);
        } else {
          // Generate a user ID from email if none provided
          final generatedId = email.hashCode.toString();
          await _storage.setUserId(generatedId);
          await _storage.setCurrentUserId(generatedId);
          print("Generated user ID from email: $generatedId");
        }

        // Try to get WooCommerce customer ID
        try {
          final customerId = await getCustomerId(email);
          if (customerId != null) {
            await _storage.setCustomerId(customerId);
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
      await _storage.clearAllUserData();

      // First check if the email already exists by trying to log in
      final loginResult = await loginWithServer(email, password);

      // If login succeeds, it means the account already exists
      if (loginResult['success']) {
        // Update the user data with the provided information
        final fullName = "$firstName $lastName";
        await _storage.setUserName(fullName);
        await _storage.setUserFirstName(firstName);
        await _storage.setUserLastName(lastName);
        await _storage.setUserPhone(mobile);
        await _storage.setUserEmail(email); // Ensure email is set

        return {
          "success": true,
          "message": "Logged in successfully",
          "email": email,
          "name": fullName,
        };
      }

      // If we reach here, we need to implement a local-first registration approach
      print("Implementing local registration workaround");

      // Generate a unique user ID based on the email
      final userId = email.hashCode.toString();
      final fullName = "$firstName $lastName";

      // Save all user data
      await _storage.setUserEmail(email);
      await _storage.setUserName(fullName);
      await _storage.setUserFirstName(firstName);
      await _storage.setUserLastName(lastName);
      await _storage.setUserPhone(mobile);
      await _storage.setUserId(userId);
      await _storage.setCurrentUserId(userId);

      // Store the complete user data in one go
      final userData = {
        "user_id": userId,
        "email": email,
        "name": fullName,
        "first_name": firstName,
        "last_name": lastName,
        "phone": mobile,
        "auth_type": "local",
      };
      await _storage.updateUserData(userData);

      // Store the password securely (you may want to use Flutter Secure Storage for this in production)
      await _storage.setLocalUserPassword(password);

      // Set a flag indicating this is a locally registered user
      await _storage.setIsLocalUser(true);

      // Mark the user as logged in
      _authToken = "local_auth_$userId"; // Pseudo token
      await _storage.setAuthToken(_authToken!);

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

    // Load token from storage if not in memory
    await _loadAuthToken();
    if (_authToken != null) return true;

    // Check for basic authentication
    final basicAuth = await _storage.getBasicAuth();
    if (basicAuth != null) {
      return true;
    }

    // Check for local authentication
    final isLocalUser = await _storage.getIsLocalUser();
    final userId = await _storage.getUserId();
    final userEmail = await _storage.getUserEmail();

    if (isLocalUser && userId != null && userEmail != null) {
      // Generate a pseudo token if needed
      if (_authToken == null) {
        _authToken = "local_auth_$userId";
        await _storage.setAuthToken(_authToken!);
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
      // Check if trying to log in with the same email
      final existingEmail = await _storage.getUserEmail();
      final isLocalUser = await _storage.getIsLocalUser();

      // Debug local user data
      final localPassword = await _storage.getLocalUserPassword();
      final authToken = await _storage.getAuthToken();
      final customerID = await _storage.getCustomerId();

      print("DEBUG: User Email: $existingEmail");
      print("DEBUG: Is Local User: $isLocalUser");
      print("DEBUG: Has Local Password: ${localPassword != null}");
      if (authToken != null) {
        print(
          "DEBUG: Auth Token: ${authToken.substring(0, min(10, authToken.length))}...",
        );
      }
      print("DEBUG: Customer ID: $customerID");

      // Only clear data if logging in with a different email
      if (existingEmail != email) {
        await _storage.clearAllUserData();
        print("Cleared previous user data - different email");
      } else {
        print("Same email - keeping existing data");
      }

      // Try local authentication first if this email matches stored local user
      if (isLocalUser && existingEmail == email) {
        final storedPassword = await _storage.getLocalUserPassword();

        if (storedPassword == password) {
          // Local login successful
          final userId =
              await _storage.getUserId() ?? email.hashCode.toString();
          final userName = await _storage.getUserName() ?? email.split('@')[0];

          // Generate a pseudo token
          _authToken = "local_auth_$userId";
          await _storage.setAuthToken(_authToken!);
          await _storage.setCurrentUserId(userId);

          // Ensure all user data is properly stored
          final userData = {
            "user_id": userId,
            "email": email,
            "name": userName,
            "auth_type": "local",
            "local_only": true,
          };
          await _storage.updateUserData(userData);

          print("Local login successful: $userId - $userName");

          return {
            "success": true,
            "email": email,
            "name": userName,
            "message": "Logged in successfully (local mode)",
            "local_only": true,
          };
        } else {
          print(
            "Local password mismatch: stored length=${storedPassword?.length}, provided length=${password.length}",
          );
        }
      }

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

        String name = authData['user_display_name'] ?? "";
        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
        } else {
          // Generate a user ID from email if none provided
          userId = email.hashCode;
        }

        // Store the auth token and user info
        await _storage.setAuthToken(authData['token']);
        _authToken = authData['token']; // Also set in memory

        // Save all user data at once for consistency
        final userData = {
          "user_id": userId,
          "email": email,
          "name": name,
          "auth_type": "jwt",
          "current_user_id": userId.toString(),
        };
        await _storage.updateUserData(userData);

        // Explicitly set these important fields to ensure they're set
        await _storage.setUserId(userId);
        await _storage.setCurrentUserId(userId.toString());
        await _storage.setUserEmail(email);
        await _storage.setUserName(name);

        // Remove local user flag if it exists
        await _storage.setIsLocalUser(false);

        // Try to get WooCommerce customer ID
        try {
          final customerId = await getCustomerId(email);
          if (customerId != null) {
            await _storage.setCustomerId(customerId);
            userData["customer_id"] = customerId;
            await _storage.updateUserData(userData);
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

      // If we reach here, try local authentication again (as a fallback)
      if (existingEmail == email && localPassword != null) {
        // Try a case-insensitive comparison for email as a fallback
        if (localPassword == password ||
            (localPassword.toLowerCase() == password.toLowerCase())) {
          final userId =
              await _storage.getUserId() ?? email.hashCode.toString();
          final userName = await _storage.getUserName() ?? email.split('@')[0];

          // Generate a pseudo token
          _authToken = "local_auth_$userId";
          await _storage.setAuthToken(_authToken!);
          await _storage.setCurrentUserId(userId);

          // Ensure we're marked as a local user
          await _storage.setIsLocalUser(true);

          print("Local login successful as fallback: $userId - $userName");

          return {
            "success": true,
            "email": email,
            "name": userName,
            "message": "Logged in successfully (local mode)",
            "local_only": true,
          };
        }
      }

      // All login methods failed
      // Try to provide a more specific error message
      if (isLocalUser && existingEmail == email) {
        return {
          "success": false,
          "error": "Incorrect password for local account.",
          "account_exists": true,
        };
      } else {
        return {
          "success": false,
          "error": "Login failed. Please check your credentials.",
          "account_exists": false,
        };
      }
    } catch (e) {
      print("Login exception: $e");
      return {
        "success": false,
        "error": "Login failed. Please check your connection and try again.",
        "debug_info": "Exception: $e",
      };
    }
  }

  // Logout method
  Future<Map<String, dynamic>> logout() async {
    try {
      await _storage.clearAllUserData();

      // Clear cached auth token
      _authToken = null;

      print("User logged out successfully - all data cleared");

      return {"success": true, "message": "Logged out successfully"};
    } catch (e) {
      print("Error during logout: $e");
      return {"success": false, "error": "Failed to log out: $e"};
    }
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
        await _storage.setAuthToken(authData['token']);
        _authToken = authData['token']; // Also set in memory
        await _storage.setUserEmail(authData['user_email'] ?? "");
        await _storage.setUserName(authData['user_display_name'] ?? "");

        if (authData['user_id'] != null) {
          await _storage.setUserId(authData['user_id']);
          await _storage.setCurrentUserId(authData['user_id'].toString());
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
        await _storage.setUserEmail(email);
        await _storage.setBasicAuth(basicAuthHeader);
        await _storage.setUserName(userData['name'] ?? "");

        if (userData['id'] != null) {
          await _storage.setUserId(userData['id']);
          await _storage.setCurrentUserId(userData['id'].toString());
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

  // Check if customer email exists
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

  // Get customer ID from email
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

  // Get authentication headers
  Future<Map<String, String>> getAuthHeaders({
    bool includeWooAuth = false,
  }) async {
    // Use cached auth token if available, otherwise load from storage
    if (_authToken == null) {
      _authToken = await _storage.getAuthToken();
    }

    final basicAuth = await _storage.getBasicAuth();

    return _apiClient.getAuthHeaders(
      includeWooAuth: includeWooAuth,
      authToken: _authToken,
      basicAuth: basicAuth,
    );
  }
}
