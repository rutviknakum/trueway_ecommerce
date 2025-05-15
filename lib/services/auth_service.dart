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

  // Server-only signup approach
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
          // User already exists and we've logged them in
          final fullName = "$firstName $lastName";
          print("Email already exists, login successful for: $email");
          return {
            "success": true,
            "message": "Logged in as existing user",
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
        // Server registration succeeded, now log in with the new credentials
        final loginResult = await loginWithServer(email, password);

        if (loginResult['success']) {
          final fullName = "$firstName $lastName";
          print("New server user registered and logged in: $email");
          return {
            "success": true,
            "message": "Account created successfully",
            "email": email,
            "name": fullName,
          };
        } else {
          // This is odd - registration succeeded but login failed
          print("WARNING: Registration succeeded but login failed");
          return {
            "success": false,
            "error":
                "Account created but login failed. Please try logging in manually.",
          };
        }
      } else {
        // Server registration failed, but we no longer create local users
        print("Server registration failed, returning error to user");
        return {
          "success": false,
          "error": "Server registration failed. Please try again later or check your internet connection.",
        };
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

  // Server registration methods are defined below

  // Improved server registration with aggressive multi-attempt approach
  Future<bool> _attemptServerRegistration(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
    try {
      print("IMPORTANT DEBUG - Registration attempt for: $email");

      // First try - WooCommerce API with fixed postcode format
      print("Trying WooCommerce API registration with modified payload");
      final customerUrl = Uri.parse(
        "${ApiConfig.baseUrl}${ApiConfig.customersEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}",
      );

      // Create a payload with explicit postcode properties to address the billing_postcode_error
      final enhancedPayload = {
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
          "address_1": "123 Any Street",
          "city": "Ahmedabad",
          "state": "Gujarat",
          "country": "IN",
          "postcode": "380015",
        },
        "shipping": {
          "first_name": firstName,
          "last_name": lastName,
          "address_1": "123 Any Street",
          "city": "Ahmedabad",
          "state": "Gujarat",
          "country": "IN",
          "postcode": "380015",
        },
        // Add additional fields that might be required
        "billing_postcode": "380015",
        "shipping_postcode": "380015",
        // Add meta data for custom fields
        "meta_data": [
          {"key": "billing_postcode", "value": "380015"},
          {"key": "_billing_postcode", "value": "380015"},
          {"key": "shipping_postcode", "value": "380015"},
          {"key": "_shipping_postcode", "value": "380015"},
        ],
      };

      print("Enhanced payload: ${json.encode(enhancedPayload)}");

      var wooResponse = await http.post(
        customerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(enhancedPayload),
      );

      print("First attempt response: ${wooResponse.statusCode}");
      print("Response body: ${wooResponse.body}");

      if (wooResponse.statusCode == 201 || wooResponse.statusCode == 200) {
        print("Success with enhanced payload!");
        return true;
      }

      // Try to parse the error response to understand what's wrong
      try {
        final errorData = json.decode(wooResponse.body);
        print("Error details: ${errorData['message'] ?? 'Unknown error'}");
      } catch (e) {
        print("Could not parse error response: $e");
      }

      // Second attempt with adjusted fields based on error feedback
      final secondPayload = {
        "email": email,
        "username": email,
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "role": "customer",
        "billing": {
          "first_name": firstName,
          "last_name": lastName,
          "company": "",
          "email": email,
          "phone": mobile,
          "address_1": "123 Main Street",
          "address_2": "",
          "city": "Ahmedabad",
          "state": "GJ",
          "postcode": "380015",
          "country": "IN",
        },
        "shipping": {
          "first_name": firstName,
          "last_name": lastName,
          "company": "",
          "address_1": "123 Main Street",
          "address_2": "",
          "city": "Ahmedabad",
          "state": "GJ",
          "postcode": "380015",
          "country": "IN",
        },
        // Try with numeric postcode instead of string
        "meta_data": [
          {"key": "billing_postcode", "value": 380015},
          {"key": "_billing_postcode", "value": 380015},
        ]
      };

      print("Second attempt with adjusted payload");
      wooResponse = await http.post(
        customerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(secondPayload),
      );

      print("Second attempt response: ${wooResponse.statusCode}");
      print("Response body: ${wooResponse.body}");

      if (wooResponse.statusCode == 201 || wooResponse.statusCode == 200) {
        print("Success with second attempt payload!");
        return true;
      }

      // Third attempt - try with a completely different approach
      print("Trying alternative approach with simplified payload");
      final simplifiedPayload = {
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
          "address_1": "123 Main Street",
          "city": "Ahmedabad",
          "state": "Gujarat",
          "country": "IN",
          // Try with zip code format that might be required by server validation
          "postcode": "38xxxx", // Intentionally invalid to see if format matters
        },
      };

      wooResponse = await http.post(
        customerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(simplifiedPayload),
      );

      print("Third attempt response: ${wooResponse.statusCode}");
      print("Response body: ${wooResponse.body}");

      if (wooResponse.statusCode == 201 || wooResponse.statusCode == 200) {
        print("Success with simplified payload!");
        return true;
      }

      // Skip to traditional WordPress registration
      print("Trying WordPress user API directly");
      final wordpressUrl = Uri.parse(
        "${ApiConfig.baseUrl}/wp/v2/users?context=edit",
      );

      // Create basic authentication header
      final authString = base64Encode(utf8.encode('${ApiConfig.consumerKey}:${ApiConfig.consumerSecret}'));

      final wordpressResponse = await http.post(
        wordpressUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Basic $authString"
        },
        body: jsonEncode({
          "username": email,
          "email": email,
          "password": password,
          "first_name": firstName,
          "last_name": lastName,
          "roles": ["customer"],
        }),
      );

      print("WordPress API response: ${wordpressResponse.statusCode}");
      print("WordPress API body: ${wordpressResponse.body}");

      if (wordpressResponse.statusCode >= 200 && wordpressResponse.statusCode < 300) {
        print("Success with WordPress direct user creation!");
        return true;
      }
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

      // Last attempt - Try basic user creation via WP REST API with authentication
      print("Trying basic user creation via REST API");
      
      try {
        // Use WP REST API with authentication to create a user
        final wpRestUrl = Uri.parse("${ApiConfig.baseUrl}/wp-json/wp/v2/users");
        
        // Get authentication headers with consumer key/secret
        final authString = base64Encode(utf8.encode('${ApiConfig.consumerKey}:${ApiConfig.consumerSecret}'));
        
        final response = await http.post(
          wpRestUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Basic $authString"
          },
          body: jsonEncode({
            "username": email,
            "email": email,
            "password": password,
            "name": "$firstName $lastName",
            "first_name": firstName,
            "last_name": lastName,
            "roles": ["customer"],
            "meta": {
              "billing_first_name": firstName,
              "billing_last_name": lastName,
              "billing_email": email,
              "billing_phone": mobile
            }
          }),
        );
        
        print("WP REST API response: ${response.statusCode}");
        if (response.statusCode != 404) {
          print("WP REST API response body: ${response.body}");
        }
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("Success with WP REST API!");
          return true;
        }
      } catch (e) {
        print("Error with WP REST API: $e");
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
