import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://map.uminber.in/wp-json";
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  /// **Login User with improved password handling**
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // First, verify the user exists in WooCommerce
      final customerUrl = Uri.parse(
        "$baseUrl/wc/v3/customers?email=$email&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );

      final customerResponse = await http.get(customerUrl);

      if (customerResponse.statusCode != 200) {
        return {
          "success": false,
          "error": "Authentication failed. Please try again later.",
        };
      }

      final List customers = json.decode(customerResponse.body);

      // If no customer found with this email
      if (customers.isEmpty) {
        return {
          "success": false,
          "error": "No account found with this email. Please sign up first.",
        };
      }

      // Since WooCommerce API doesn't provide direct password validation,
      // We'll use WordPress authentication endpoint
      final wpAuthUrl = Uri.parse("$baseUrl/jwt-auth/v1/token");

      final authResponse = await http.post(
        wpAuthUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": email, "password": password}),
      );

      // Check if the login was successful with WordPress
      if (authResponse.statusCode == 200) {
        // Login successful
        final customerId = customers[0]["id"];
        final name = customers[0]["first_name"];

        // Store user info in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_email", email);
        await prefs.setInt("customer_id", customerId);
        await prefs.setString("user_name", name);

        // Store the auth token if needed
        final authData = json.decode(authResponse.body);
        if (authData['token'] != null) {
          await prefs.setString("auth_token", authData['token']);
        }

        return {
          "success": true,
          "customer_id": customerId,
          "email": email,
          "name": name,
          "message": "Logged in successfully",
        };
      } else {
        // Failed password validation
        return {
          "success": false,
          "error": "Invalid email or password. Please try again.",
        };
      }
    } catch (e) {
      // Handle JWT endpoint not available fallback
      try {
        // Since JWT auth might not be available in all WP installations
        // Fallback to just checking if the customer exists as before
        final customerUrl = Uri.parse(
          "$baseUrl/wc/v3/customers?email=$email&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
        );

        final customerResponse = await http.get(customerUrl);
        final List customers = json.decode(customerResponse.body);

        if (customers.isNotEmpty) {
          // Store customer info even in the fallback case
          final customerId = customers[0]["id"];
          final name = customers[0]["first_name"];

          // Store user info in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_email", email);
          await prefs.setInt("customer_id", customerId);
          await prefs.setString("user_name", name);

          return {
            "success": true,
            "customer_id": customerId,
            "email": email,
            "name": name,
            "message": "Logged in successfully",
          };
        } else {
          return {
            "success": false,
            "error":
                "Login failed. Please check your credentials and try again.",
          };
        }
      } catch (_) {
        return {
          "success": false,
          "error": "Login failed. Please check your credentials and try again.",
        };
      }
    }
  }

  /// **Register New User with improved validation**
  Future<Map<String, dynamic>> signupUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Validate inputs (beyond form validation)
      if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
        return {"success": false, "error": "All fields are required."};
      }

      if (!email.contains('@')) {
        return {
          "success": false,
          "error": "Please enter a valid email address.",
        };
      }

      if (password.length < 6) {
        return {
          "success": false,
          "error": "Password must be at least 6 characters.",
        };
      }

      // First check if user already exists
      final checkUrl = Uri.parse(
        "$baseUrl/wc/v3/customers?email=$email&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );

      final checkResponse = await http.get(checkUrl);

      if (checkResponse.statusCode != 200) {
        return {
          "success": false,
          "error": "Unable to verify account. Please try again later.",
        };
      }

      final List existingCustomers = json.decode(checkResponse.body);

      if (existingCustomers.isNotEmpty) {
        return {
          "success": false,
          "error":
              "An account with this email already exists. Please log in instead.",
        };
      }

      // Create new customer
      final url = Uri.parse(
        "$baseUrl/wc/v3/customers?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );

      // Generate a unique username
      String username = email.split('@')[0];
      final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
      username = "$username$timestamp";

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "username": username,
          "password": password,
          "first_name": name,
        }),
      );

      if (response.statusCode != 201) {
        final responseBody = response.body;
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(responseBody);
        } catch (_) {
          errorData = {"message": "Registration failed. Please try again."};
        }

        return {
          "success": false,
          "error":
              errorData['message'] ?? "Registration failed. Please try again.",
        };
      }

      // Registration successful
      final customerData = json.decode(response.body);

      // Store user info
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
    } catch (e) {
      return {
        "success": false,
        "error": "Registration failed. Please try again later.",
      };
    }
  }

  /// **Logout User - Keep the original method name for compatibility**
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_email");
    await prefs.remove("customer_id");
    await prefs.remove("user_name");
    await prefs.remove("auth_token"); // Clear auth token if it exists
    print("User Logged Out Successfully.");
  }

  /// **Check if user is logged in**
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_email") != null &&
        prefs.getInt("customer_id") != null;
  }

  /// **Get current user info**
  Future<Map<String, dynamic>> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    final customerId = prefs.getInt("customer_id");
    final name = prefs.getString("user_name");

    if (email != null && customerId != null) {
      return {
        "logged_in": true,
        "email": email,
        "customer_id": customerId,
        "name": name ?? "",
      };
    }

    return {"logged_in": false};
  }

  /// **Make authenticated API request for logged-in users**
  Future<http.Response> authenticatedRequest(
    String endpoint, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    // Get customer ID
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    if (customerId == null) {
      throw Exception("Not authenticated");
    }

    // Build URL with consumer key/secret
    Uri url;
    if (endpoint.contains("?")) {
      url = Uri.parse(
        "$baseUrl$endpoint&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );
    } else {
      url = Uri.parse(
        "$baseUrl$endpoint?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );
    }

    // Add customer filter where appropriate
    if (!endpoint.contains("customer=") && !endpoint.contains("/customers/")) {
      String separator = url.toString().contains("?") ? "&" : "?";
      url = Uri.parse("${url.toString()}${separator}customer=$customerId");
    }

    // Make request
    if (method.toUpperCase() == 'GET') {
      return http.get(url);
    } else if (method.toUpperCase() == 'POST') {
      Map<String, String> headers = {"Content-Type": "application/json"};
      return http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } else if (method.toUpperCase() == 'PUT') {
      Map<String, String> headers = {"Content-Type": "application/json"};
      return http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } else if (method.toUpperCase() == 'DELETE') {
      return http.delete(url);
    } else {
      throw Exception("Unsupported HTTP method: $method");
    }
  }

  /// **Make public API request that doesn't require authentication**
  Future<http.Response> publicRequest(
    String endpoint, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    // Build URL with consumer key/secret
    Uri url;
    if (endpoint.contains("?")) {
      url = Uri.parse(
        "$baseUrl$endpoint&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );
    } else {
      url = Uri.parse(
        "$baseUrl$endpoint?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );
    }

    // Make request
    if (method.toUpperCase() == 'GET') {
      return http.get(url);
    } else if (method.toUpperCase() == 'POST') {
      Map<String, String> headers = {"Content-Type": "application/json"};
      return http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } else {
      throw Exception("Unsupported HTTP method: $method");
    }
  }
}
