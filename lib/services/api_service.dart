import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
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
        await prefs.setString("user_email", email);

        String name = authData['user_display_name'] ?? "";
        await prefs.setString("user_name", name);

        int userId = 0;
        if (authData['user_id'] != null) {
          userId = authData['user_id'];
          await prefs.setInt("user_id", userId);
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
        await prefs.setString("user_email", authData['user_email'] ?? "");
        await prefs.setString("user_name", authData['user_display_name'] ?? "");

        if (authData['user_id'] != null) {
          await prefs.setInt("user_id", authData['user_id']);
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

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Input validation with more detailed logging
      print("Starting signup process for email: $email");

      name = name.trim();
      email = email.trim();

      if (name.isEmpty) {
        print("Signup validation failed: Name is empty");
        return {"success": false, "error": "Name is required."};
      }
      if (email.isEmpty || !email.contains('@')) {
        print("Signup validation failed: Invalid email format");
        return {
          "success": false,
          "error": "Please enter a valid email address.",
        };
      }
      if (password.isEmpty || password.length < 6) {
        print("Signup validation failed: Password too short");
        return {
          "success": false,
          "error": "Password must be at least 6 characters.",
        };
      }

      // Check if user already exists
      print("Checking if email exists: $email");
      final exists = await checkEmailExists(email);
      if (exists) {
        print("Signup failed: Email already exists");
        return {
          "success": false,
          "error":
              "An account with this email already exists. Please log in instead.",
        };
      }

      // Generate a unique username
      String username = email.split('@')[0];
      final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
      username = "$username$timestamp";
      print("Generated username: $username");

      // Create new customer with complete data structure
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.customersEndpoint));

      // Build a complete customer data structure with all required fields
      final Map<String, dynamic> customerData = {
        "email": email,
        "username": username,
        "password": password,
        "first_name": name,
        "last_name": "",
        "billing": {
          "first_name": name,
          "last_name": "",
          "company": "",
          "address_1": "",
          "address_2": "",
          "city": "",
          "state": "",
          "postcode": "000000",
          "country": "",
          "email": email,
          "phone": "",
        },
        "shipping": {
          "first_name": name,
          "last_name": "",
          "company": "",
          "address_1": "",
          "address_2": "",
          "city": "",
          "state": "",
          "postcode": "000000",
          "country": "",
        },
      };

      final requestBody = jsonEncode(customerData);
      print("Sending customer creation request to WooCommerce");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      print("Customer creation response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        final customerData = json.decode(response.body);
        print("Registration successful! Customer ID: ${customerData["id"]}");

        // Try auto login
        print("Attempting auto-login after registration");
        final loginResponse = await login(email, password);
        if (loginResponse['success']) {
          print("Auto-login successful");
          return {
            "success": true,
            "customer_id": customerData["id"],
            "email": email,
            "name": name,
            "message": "Account created and logged in successfully",
          };
        } else {
          // Store basic user info if login fails
          print("Auto-login failed, storing basic user info");
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_email", email);
          await prefs.setInt("customer_id", customerData["id"]);
          await prefs.setString("user_name", name);

          return {
            "success": true,
            "customer_id": customerData["id"],
            "email": email,
            "name": name,
            "message": "Account created successfully",
          };
        }
      } else {
        // Registration failed
        print("Registration failed with status: ${response.statusCode}");
        String errorMessage = "Registration failed. Please try again.";
        try {
          final errorData = json.decode(response.body);
          print("Error data: $errorData");
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
            // Clean up HTML tags from error message
            errorMessage = errorMessage
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&quot;', '"');
            print("Cleaned error message: $errorMessage");
          }
        } catch (e) {
          print("Error parsing registration error: $e");
        }
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      print("Signup exception: $e");
      return {
        "success": false,
        "error": "Registration failed. Please try again later.",
      };
    }
  }

  // Add this new method for admin-based signup
  Future<Map<String, dynamic>> signupWithAdmin(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Admin credentials
      final adminUsername = "uminberdesigns"; // Your admin username
      final adminPassword = "f5KILLHNanhPF9DwJjATIDgV"; // Your app password

      // Input validation
      name = name.trim();
      email = email.trim();

      if (name.isEmpty) {
        return {"success": false, "error": "Name is required."};
      }
      if (email.isEmpty || !email.contains('@')) {
        return {
          "success": false,
          "error": "Please enter a valid email address.",
        };
      }
      if (password.isEmpty || password.length < 6) {
        return {
          "success": false,
          "error": "Password must be at least 6 characters.",
        };
      }

      // Check if user already exists by email
      final exists = await _checkUserExists(email);
      if (exists) {
        return {
          "success": false,
          "error": "Account already exists. Please log in instead.",
        };
      }

      // Create Basic Auth token for admin
      final token = base64.encode(utf8.encode('$adminUsername:$adminPassword'));

      // Generate a unique username
      final username =
          email.split('@')[0] +
          DateTime.now().millisecondsSinceEpoch.toString().substring(0, 4);

      // Create user data - minimal fields required
      final userData = {
        "username": username,
        "email": email,
        "password": password,
        "name": name,
        "roles": ["customer"],
      };

      // WordPress users endpoint
      final url = Uri.parse('${ApiConfig.baseUrl}/wp/v2/users');

      print("Sending user creation request: ${jsonEncode(userData)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Basic $token",
        },
        body: jsonEncode(userData),
      );

      print("User creation response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("User created successfully with ID: ${responseData['id']}");

        // Store user info
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_email", email);
        await prefs.setString("user_name", name);

        if (responseData['id'] != null) {
          await prefs.setInt("user_id", responseData['id']);
        }

        // Try to log in the new user
        final loginResponse = await login(email, password);
        if (loginResponse['success']) {
          return {
            "success": true,
            "user_id": responseData['id'],
            "email": email,
            "name": name,
            "message": "Account created and logged in successfully",
          };
        } else {
          return {
            "success": true,
            "user_id": responseData['id'],
            "email": email,
            "name": name,
            "message": "Account created successfully. Please log in.",
          };
        }
      } else {
        // Failed to create user
        String errorMessage = "Registration failed. Please try again.";
        try {
          final errorData = json.decode(response.body);
          print("Error data: $errorData");

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
            // Clean up HTML tags from error message
            errorMessage =
                errorMessage
                    .replaceAll(RegExp(r'<[^>]*>'), ' ')
                    .replaceAll('&quot;', '"')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
          }
        } catch (e) {
          print("Error parsing registration error: $e");
        }
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      print("Signup with admin exception: $e");
      return {
        "success": false,
        "error": "Registration failed. Please try again later.",
      };
    }
  }

  // Helper method to check if a user exists by email
  Future<bool> _checkUserExists(String email) async {
    try {
      // First try to check via WooCommerce customers endpoint
      final customersUrl = Uri.parse(
        ApiConfig.buildUrl(
          ApiConfig.customersEndpoint,
          queryParams: {"email": email},
        ),
      );

      final customersResponse = await http.get(customersUrl);
      if (customersResponse.statusCode == 200) {
        final List customers = json.decode(customersResponse.body);
        if (customers.isNotEmpty) {
          return true;
        }
      }

      // If no customer found, we can't directly check WordPress users by email without admin auth
      // We'll check indirectly by trying to use the JWT endpoint with the email
      final jwtUrl = Uri.parse(ApiConfig.baseUrl + ApiConfig.authEndpoint);
      final jwtResponse = await http.post(
        jwtUrl,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": email, "password": "check_only_not_real_password"},
      );

      if (jwtResponse.statusCode == 200) {
        // Should never happen with wrong password
        return true;
      }

      try {
        final errorData = json.decode(jwtResponse.body);
        // If error code indicates incorrect password, the user exists
        if (errorData['code'] == '[jwt_auth] incorrect_password') {
          return true;
        }
      } catch (e) {
        print("Error parsing JWT response: $e");
      }

      return false;
    } catch (e) {
      print("Error checking if user exists: $e");
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_email");
    await prefs.remove("customer_id");
    await prefs.remove("user_id");
    await prefs.remove("user_name");
    await prefs.remove("auth_token");
    await prefs.remove("basic_auth");
    print("User logged out successfully");
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");
    return token != null || basicAuth != null;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    final customerId = prefs.getInt("customer_id");
    final userId = prefs.getInt("user_id");
    final name = prefs.getString("user_name");
    final token = prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    if ((token != null || basicAuth != null) && email != null) {
      return {
        "logged_in": true,
        "email": email,
        "customer_id": customerId ?? 0,
        "user_id": userId ?? 0,
        "name": name ?? "",
        "auth_type": token != null ? "jwt" : "basic",
      };
    }
    return {"logged_in": false};
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
  Future<Map<String, String>> getAuthHeaders() async {
    Map<String, String> headers = {"Content-Type": "application/json"};

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    } else if (basicAuth != null) {
      headers["Authorization"] = basicAuth;
    }

    return headers;
  }

  Future<http.Response> authenticatedRequest(
    String endpoint, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    // Check auth status
    final isAuth = await isLoggedIn();
    if (!isAuth) {
      throw Exception("Not authenticated");
    }

    // Get auth headers and customer ID
    Map<String, String> headers = await getAuthHeaders();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    // Build URL with customer ID if applicable
    String urlString = ApiConfig.buildUrl(endpoint);
    if (customerId != null &&
        !endpoint.contains("customer=") &&
        !endpoint.contains("/customers/")) {
      String separator = urlString.contains("?") ? "&" : "?";
      urlString = "$urlString${separator}customer=$customerId";
    }

    final url = Uri.parse(urlString);

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          return await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw Exception("Unsupported HTTP method: $method");
      }
    } catch (e) {
      print("Error in authenticated request: $e");
      rethrow;
    }
  }

  Future<http.Response> publicRequest(
    String endpoint, {
    required String method,
    Map<String, dynamic>? body,
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
}
