// auth_service.dart
import 'dart:convert';
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

  // Authentication methods with server priority
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": email, "password": password}),
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

        // Set is_local_user to false since this is a server login
        await _storage.setIsLocalUser(false);

        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
          await _storage.setUserId(userId.toString());
          await _storage.setCurrentUserId(userId.toString());

          // Store the entire user data in one go
          final userData = {
            "user_id": userId.toString(),
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

  // Server-first signup approach
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
      // First check if the email already exists
      final emailExists = await checkEmailExists(email);

      if (emailExists) {
        // If email exists, try to log in
        final loginResult = await loginWithServer(email, password);

        if (loginResult['success']) {
          // Update the user data with the provided information
          final fullName = "$firstName $lastName";
          await _storage.setUserName(fullName);
          await _storage.setUserFirstName(firstName);
          await _storage.setUserLastName(lastName);
          await _storage.setUserPhone(mobile);
          await _storage.setUserEmail(email);
          await _storage.setIsLocalUser(false);

          return {
            "success": true,
            "message": "Logged in successfully",
            "email": email,
            "name": fullName,
          };
        } else {
          // Email exists but password doesn't match
          return {
            "success": false,
            "error":
                "An account with this email already exists. Please log in instead.",
            "account_exists": true,
          };
        }
      }

      // Email doesn't exist, proceed with server registration
      print("Attempting server registration for new user: $email");
      final serverResult = await _attemptServerRegistration(
        firstName,
        lastName,
        mobile,
        email,
        password,
      );

      if (serverResult) {
        // Server registration successful, log in
        print("Server registration successful, attempting login");

        // Wait briefly for server to process the registration
        await Future.delayed(Duration(milliseconds: 500));

        final loginAfterRegister = await loginWithServer(email, password);
        if (loginAfterRegister['success']) {
          return {
            "success": true,
            "message": "Account created successfully on server",
            "email": email,
            "name": "$firstName $lastName",
            "local_only": false,
          };
        } else {
          // Registration seemed to succeed but login failed - this is odd
          print(
            "Warning: User created on server but login failed. Login error: ${loginAfterRegister['error']}",
          );

          // Create a temporary local user as a fallback
          return await _createLocalUserAsFallback(
            firstName,
            lastName,
            mobile,
            email,
            password,
          );
        }
      } else {
        // Server registration failed, create local user as fallback
        print("Server registration failed, creating local user as fallback");
        return await _createLocalUserAsFallback(
          firstName,
          lastName,
          mobile,
          email,
          password,
        );
      }
    } catch (e) {
      print("Signup exception: $e");
      return {
        "success": false,
        "error": "Registration failed. Please check your connection.",
        "debug_info": "Exception: $e",
      };
    }
  }

  // Create local user as fallback when server registration fails
  Future<Map<String, dynamic>> _createLocalUserAsFallback(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
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

    // Store the password securely
    await _storage.setLocalUserPassword(password);

    // Set a flag indicating this is a locally registered user
    await _storage.setIsLocalUser(true);

    // Mark the user as logged in
    _authToken = "local_auth_$userId"; // Pseudo token
    await _storage.setAuthToken(_authToken!);

    print("Local user registration (fallback) successful: $userId - $fullName");

    return {
      "success": true,
      "message": "Account created locally (server registration failed)",
      "email": email,
      "name": fullName,
      "local_only": true,
    };
  }

  // Improved server registration with aggressive multi-attempt approach
  Future<bool> _attemptServerRegistration(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
    try {
      // Using multiple valid postal codes to ensure one works
      final validPostalCodes = [
        "382421",
        "380001",
        "380015",
        "382424",
        "380005",
      ];
      String validPostalCode = validPostalCodes[0]; // Start with first one

      print("IMPORTANT DEBUG - Registration attempt for: $email");

      // First try - WooCommerce API with minimal payload
      print("Trying WooCommerce API registration with minimal payload");
      final customerUrl = Uri.parse(
        "${ApiConfig.baseUrl}${ApiConfig.customersEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}",
      );

      // Create an absolute minimal payload first to avoid validation issues
      final minimalPayload = {
        "email": email,
        "username": email,
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "billing": {
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "phone": mobile,
          "postcode": validPostalCode,
        },
      };

      print("Minimal payload: ${json.encode(minimalPayload)}");

      var wooResponse = await http.post(
        customerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(minimalPayload),
      );

      print("First attempt response: ${wooResponse.statusCode}");
      print("Response body: ${wooResponse.body}");

      if (wooResponse.statusCode == 201 || wooResponse.statusCode == 200) {
        print("Success with minimal payload!");
        return true;
      }

      // Second try - Loop through different postal codes
      for (int i = 1; i < validPostalCodes.length; i++) {
        validPostalCode = validPostalCodes[i];
        print("Trying with different postal code: $validPostalCode");

        final fullPayload = {
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
            "address_1": "123 Main Street",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "postcode": validPostalCode,
            "country": "IN",
          },
          "shipping": {
            "first_name": firstName,
            "last_name": lastName,
            "address_1": "123 Main Street",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "postcode": validPostalCode,
            "country": "IN",
          },
        };

        wooResponse = await http.post(
          customerUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(fullPayload),
        );

        print("Attempt #${i + 1} response: ${wooResponse.statusCode}");
        print("Response body: ${wooResponse.body}");

        if (wooResponse.statusCode == 201 || wooResponse.statusCode == 200) {
          print("Success with postal code: $validPostalCode");
          return true;
        }
      }

      // Third try - Use a direct REST API endpoint
      print("Trying alternative WooCommerce endpoint");
      final directUrl = Uri.parse(
        "${ApiConfig.baseUrl}/wp-json/wc/v3/customers/direct-register?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}",
      );

      final directResponse = await http.post(
        directUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "username": email,
          "first_name": firstName,
          "last_name": lastName,
        }),
      );

      print("Direct endpoint response: ${directResponse.statusCode}");
      print("Direct endpoint body: ${directResponse.body}");

      if (directResponse.statusCode >= 200 && directResponse.statusCode < 300) {
        print("Success with direct endpoint!");
        return true;
      }

      // Fourth try - Traditional WordPress registration
      print("Trying WordPress user API");
      final wpUrl = Uri.parse("${ApiConfig.baseUrl}/wp-json/wp/v2/users");

      // Get admin credentials for WordPress API
      final headers = {
        "Content-Type": "application/json",
        "Authorization":
            "Basic " +
            base64Encode(
              utf8.encode(
                '${ApiConfig.consumerKey}:${ApiConfig.consumerSecret}',
              ),
            ),
      };

      final wpResponse = await http.post(
        wpUrl,
        headers: headers,
        body: jsonEncode({
          "username": email,
          "email": email,
          "password": password,
          "name": "$firstName $lastName",
        }),
      );

      print("WordPress response: ${wpResponse.statusCode}");
      print("WordPress body: ${wpResponse.body}");

      if (wpResponse.statusCode >= 200 && wpResponse.statusCode < 300) {
        print("Success with WordPress API!");
        return true;
      }

      // Final attempt - Try a public endpoint if available
      print("Trying JWT registration endpoint");
      final jwtRegisterUrl = Uri.parse(
        "${ApiConfig.baseUrl}/wp-json/jwt-auth/v1/register",
      );

      final jwtResponse = await http.post(
        jwtRegisterUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": email,
          "email": email,
          "password": password,
          "name": "$firstName $lastName",
        }),
      );

      print("JWT register response: ${jwtResponse.statusCode}");
      print("JWT register body: ${jwtResponse.body}");

      if (jwtResponse.statusCode >= 200 && jwtResponse.statusCode < 300) {
        print("Success with JWT register!");
        return true;
      }

      print("All registration attempts failed");
      return false;
    } catch (e) {
      print("Server registration error: $e");
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      // First check if there's a standard auth token
      if (_authToken != null &&
          _authToken!.isNotEmpty &&
          _authToken != 'null') {
        // Validate that we also have a user email - extra check for data consistency
        final email = await _storage.getUserEmail();
        return email != null && email.isNotEmpty;
      }

      // Load token from storage if not in memory
      await _loadAuthToken();
      if (_authToken != null &&
          _authToken!.isNotEmpty &&
          _authToken != 'null') {
        // Validate that we also have a user email - extra check for data consistency
        final email = await _storage.getUserEmail();
        return email != null && email.isNotEmpty;
      }

      // Check for basic authentication
      final basicAuth = await _storage.getBasicAuth();
      if (basicAuth != null && basicAuth.isNotEmpty) {
        // Validate that we also have a user email - extra check for data consistency
        final email = await _storage.getUserEmail();
        return email != null && email.isNotEmpty;
      }

      // Check for local authentication
      final isLocalUser = await _storage.getIsLocalUser();
      final userId = await _storage.getUserId();
      final userEmail = await _storage.getUserEmail();
      final localPassword = await _storage.getLocalUserPassword();

      if (isLocalUser &&
          userId != null &&
          userEmail != null &&
          localPassword != null &&
          userId.isNotEmpty &&
          userEmail.isNotEmpty &&
          localPassword.isNotEmpty) {
        // Generate a pseudo token if needed
        if (_authToken == null || _authToken!.isEmpty || _authToken == 'null') {
          _authToken = "local_auth_$userId";
          await _storage.setAuthToken(_authToken!);
        }
        return true;
      }

      return false;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // Login method that tries server first, then local
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {"success": false, "error": "Email and password are required"};
    }

    try {
      // Try server authentication first
      print("Attempting server login with email: $email");

      // JWT authentication with server
      final jwtUrl = Uri.parse(ApiConfig.baseUrl + ApiConfig.authEndpoint);
      final jwtResponse = await http.post(
        jwtUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": email, "password": password}),
      );

      print("JWT Auth response status: ${jwtResponse.statusCode}");

      // If JWT auth succeeded, use it
      if (jwtResponse.statusCode == 200) {
        final authData = json.decode(jwtResponse.body);

        String name = authData['user_display_name'] ?? "";
        String userId = "0";
        if (authData['user_id'] != null) {
          userId = authData['user_id'].toString();
        } else {
          // Generate a user ID from email if none provided
          userId = email.hashCode.toString();
        }

        // First, clear any existing tokens to prevent conflicts
        await _storage.setAuthToken("");
        await _storage.setBasicAuth("");

        // Then store the new auth token and user info
        await _storage.setAuthToken(authData['token']);
        _authToken = authData['token']; // Also set in memory

        // Save all user data at once for consistency
        final userData = {
          "user_id": userId,
          "email": email,
          "name": name,
          "auth_type": "jwt",
          "current_user_id": userId,
        };
        await _storage.updateUserData(userData);

        // Explicitly set these important fields to ensure they're set
        await _storage.setUserId(userId);
        await _storage.setCurrentUserId(userId);
        await _storage.setUserEmail(email);
        await _storage.setUserName(name);

        // Set local user flag to false
        await _storage.setIsLocalUser(false);

        // Clear local password if it exists
        await _storage.setLocalUserPassword("");

        // Try to get WooCommerce customer ID
        try {
          final customerId = await getCustomerId(email);
          if (customerId != null) {
            await _storage.setCustomerId(customerId);
            userData["customer_id"] = customerId.toString();
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

      // If server auth failed, check if we have a local user with this email
      print("Server login failed, checking for local user");
      final existingEmail = await _storage.getUserEmail();
      final isLocalUser = await _storage.getIsLocalUser();
      final localPassword = await _storage.getLocalUserPassword();

      // Try local authentication as fallback
      if (isLocalUser && existingEmail == email && localPassword == password) {
        final userId = await _storage.getUserId() ?? email.hashCode.toString();
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

      // All login methods failed
      return {
        "success": false,
        "error": "Login failed. Please check your credentials.",
        "account_exists": await checkEmailExists(email) ? true : false,
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
      // Clear all authentication data
      await _storage.setAuthToken('');
      await _storage.setBasicAuth('');

      // Also clear the in-memory token
      _authToken = null;

      // Important: Set is_local_user to false
      await _storage.setIsLocalUser(false);

      // Clear local password
      await _storage.setLocalUserPassword('');

      print("User logged out successfully - auth tokens cleared");

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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final authData = json.decode(response.body);

        // Clear existing tokens first
        await _storage.setAuthToken("");
        await _storage.setBasicAuth("");

        // Set the new token
        await _storage.setAuthToken(authData['token']);
        _authToken = authData['token']; // Also set in memory

        // Set user data
        await _storage.setUserEmail(authData['user_email'] ?? "");
        await _storage.setUserName(authData['user_display_name'] ?? "");
        await _storage.setIsLocalUser(false);

        if (authData['user_id'] != null) {
          String userId = authData['user_id'].toString();
          await _storage.setUserId(userId);
          await _storage.setCurrentUserId(userId);
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

        // Clear existing tokens first
        await _storage.setAuthToken("");

        // Set the new auth data
        await _storage.setBasicAuth(basicAuthHeader);
        await _storage.setUserEmail(email);
        await _storage.setUserName(userData['name'] ?? "");
        await _storage.setIsLocalUser(false);

        if (userData['id'] != null) {
          String userId = userData['id'].toString();
          await _storage.setUserId(userId);
          await _storage.setCurrentUserId(userId);
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

  // Password reset functionality
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    if (email.isEmpty) {
      return {"success": false, "error": "Email address is required"};
    }

    try {
      print("Requesting password reset for email: $email");

      // Check if the email exists first
      final emailExists = await checkEmailExists(email);
      if (!emailExists) {
        return {
          "success": false,
          "error": "No account found with this email address",
        };
      }

      // Try the standard WordPress password reset endpoint
      final resetUrl = Uri.parse(
        "${ApiConfig.baseUrl}/wp/v2/users/lostpassword",
      );

      final response = await http.post(
        resetUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_login": email}),
      );

      print("Password reset response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": "Password reset instructions sent to your email",
        };
      }

      // If the standard endpoint fails, try an alternative endpoint
      final alternativeUrl = Uri.parse(
        "${ApiConfig.baseUrl}/simple-jwt-login/v1/reset-password",
      );

      final alternativeResponse = await http.post(
        alternativeUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      print(
        "Alternative password reset response: ${alternativeResponse.statusCode}",
      );

      if (alternativeResponse.statusCode == 200) {
        return {
          "success": true,
          "message": "Password reset instructions sent to your email",
        };
      }

      // Both attempts failed, return an error
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          return {"success": false, "error": errorData['message']};
        }
      } catch (e) {
        print("Error parsing reset password response: $e");
      }

      return {
        "success": false,
        "error": "Unable to process your request. Please try again later.",
      };
    } catch (e) {
      print("Password reset error: $e");
      return {
        "success": false,
        "error":
            "Failed to connect to the server. Please check your connection.",
      };
    }
  }
}
