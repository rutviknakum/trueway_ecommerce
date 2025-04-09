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
        _authToken = authData['token']; // Also set in memory
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

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return {"success": false, "error": "All fields are required"};
    }

    try {
      // First check if the email already exists
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        return {
          "success": false,
          "error":
              "This email is already registered. Please use another email or login.",
        };
      }

      // Create a new customer
      final customerUrl = Uri.parse(
        ApiConfig.buildUrl(ApiConfig.customersEndpoint),
      );

      final response = await http.post(
        customerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "first_name": name.split(' ').first,
          "last_name":
              name.split(' ').length > 1
                  ? name.split(' ').skip(1).join(' ')
                  : "",
          "username": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        final customerData = json.decode(response.body);

        // Store customer ID for later use
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (customerData['id'] != null) {
          await prefs.setInt("customer_id", customerData['id']);
        }

        // Automatically log the user in
        return await login(email, password);
      } else {
        // Handle error response
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            final cleanMessage = errorData['message']
                .replaceAll('<strong>', '')
                .replaceAll('</strong>', '')
                .replaceAll('<br />', ' ');
            return {"success": false, "error": cleanMessage};
          }
        } catch (e) {
          print("Error parsing signup response: $e");
        }

        return {
          "success": false,
          "error": "Registration failed. Please try again.",
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

  // Updated logout method that returns a response
  Future<Map<String, dynamic>> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("user_email");
      await prefs.remove("customer_id");
      await prefs.remove("user_id");
      await prefs.remove("user_name");
      await prefs.remove("auth_token");
      await prefs.remove("basic_auth");
      _authToken = null; // Also clear from memory

      print("User logged out successfully");

      return {"success": true, "message": "Logged out successfully"};
    } catch (e) {
      print("Error during logout: $e");
      return {"success": false, "error": "Failed to log out: $e"};
    }
  }

  Future<bool> isLoggedIn() async {
    if (_authToken != null) return true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    if (token != null) {
      _authToken = token; // Cache it in memory
    }

    return token != null || basicAuth != null;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    final customerId = prefs.getInt("customer_id");
    final userId = prefs.getInt("user_id");
    final name = prefs.getString("user_name");

    // Check memory first, then shared preferences
    final token = _authToken ?? prefs.getString("auth_token");
    final basicAuth = prefs.getString("basic_auth");

    if ((token != null || basicAuth != null) && email != null) {
      return {
        "logged_in": true,
        "email": email,
        "customer_id": customerId,
        "user_id": userId,
        "name": name ?? "",
        "auth_type": token != null ? "jwt" : "basic",
      };
    }
    return {"logged_in": false};
  }

  // Helper method to update the current user data in SharedPreferences
  Future<void> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (userData.containsKey('name') && userData['name'] != null) {
        await prefs.setString("user_name", userData['name']);
      }

      if (userData.containsKey('email') && userData['email'] != null) {
        await prefs.setString("user_email", userData['email']);
      }

      // Store other user data as needed
      if (userData.containsKey('phone') && userData['phone'] != null) {
        await prefs.setString("user_phone", userData['phone']);
      }

      if (userData.containsKey('address') && userData['address'] != null) {
        await prefs.setString("user_address", userData['address']);
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
      if (userData['name'] != null) {
        await prefs.setString("user_name", userData['name']);
      }
      if (userData['phone'] != null) {
        await prefs.setString("user_phone", userData['phone']);
      }
      if (userData['address'] != null) {
        await prefs.setString("user_address", userData['address']);
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

          // Extract first and last name from full name
          String firstName = userData['name'] ?? '';
          String lastName = '';

          if (firstName.contains(' ')) {
            final nameParts = firstName.split(' ');
            firstName = nameParts.first;
            lastName = nameParts.sublist(1).join(' ');
          }

          // Create properly structured update payload
          final Map<String, dynamic> updateData = {
            'first_name': firstName,
            'last_name': lastName,
            'billing': {
              'first_name': firstName,
              'last_name': lastName,
              'phone': userData['phone'] ?? '',
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
                addressComponents['postalCode'] ?? '';
            updateData['billing']['country'] =
                addressComponents['country'] ?? '';

            // Also update shipping address
            updateData['shipping']['address_1'] =
                addressComponents['street'] ?? '';
            updateData['shipping']['city'] = addressComponents['city'] ?? '';
            updateData['shipping']['state'] = addressComponents['state'] ?? '';
            updateData['shipping']['postcode'] =
                addressComponents['postalCode'] ?? '';
            updateData['shipping']['country'] =
                addressComponents['country'] ?? '';
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

      // Create update payload
      final Map<String, dynamic> updateData = {
        'name': userData['name'],
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

  // IMPROVED: Enhanced authenticated request method with WooCommerce auth handling
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

  // ADDED: Method to generate WooCommerce auth string for URLs

  // ADDED: Get orders for current user with proper handling
  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int perPage = 10,
    String status = 'any',
  }) async {
    try {
      // Check login status
      final userInfo = await getCurrentUser();
      if (!userInfo["logged_in"]) {
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
      }

      // Make request with WooCommerce authentication
      final response = await authenticatedRequest(
        ApiConfig.ordersEndpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        List<dynamic> orders = json.decode(response.body);
        return orders.cast<Map<String, dynamic>>();
      } else {
        print("Failed to fetch orders: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  // ADDED: Get single order by ID with proper handling
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
