// user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';
import 'api_client.dart';

class UserService {
  final StorageService _storage;
  final ApiClient _apiClient;

  UserService(this._storage, this._apiClient);

  // Get current user details
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final email = await _storage.getUserEmail();
      final customerId = await _storage.getCustomerId();
      final userId = await _storage.getUserId();
      final name = await _storage.getUserName();
      final phone = await _storage.getUserPhone();
      final firstName = await _storage.getUserFirstName();
      final lastName = await _storage.getUserLastName();
      final isLocalUser = await _storage.getIsLocalUser();
      final currentUserId = await _storage.getCurrentUserId();

      // Check for auth tokens
      final token = await _storage.getAuthToken();
      final basicAuth = await _storage.getBasicAuth();

      // Debug the current user state
      print("DEBUG - getCurrentUser - Email: $email");
      print("DEBUG - getCurrentUser - User ID: $userId");
      print("DEBUG - getCurrentUser - Customer ID: $customerId");
      print(
        "DEBUG - getCurrentUser - Token: ${token != null ? 'exists' : 'null'}",
      );
      print(
        "DEBUG - getCurrentUser - Basic Auth: ${basicAuth != null ? 'exists' : 'null'}",
      );
      print("DEBUG - getCurrentUser - Is Local User: $isLocalUser");

      // Verify we have a consistent user ID
      if (userId != null && currentUserId != null && userId != currentUserId) {
        print("Warning: User ID mismatch detected. Fixing...");
        await _storage.setCurrentUserId(userId);
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
          "auth_type":
              isLocalUser ? "local" : (token != null ? "jwt" : "basic"),
          "local_only": isLocalUser,
        };

        // Add additional user data if available
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

      print("User not logged in - returning logged_in: false");
      return {"logged_in": false};
    } catch (e) {
      print("Error in getCurrentUser: $e");
      return {"logged_in": false, "error": e.toString()};
    }
  }

  // Update user profile in both local storage and the server
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    try {
      // Get customer ID and user ID
      final customerId = userData['customer_id']?.toString();
      final userId = userData['user_id']?.toString();

      // Store updated data in local storage
      await _storage.updateUserData(userData);

      // Update WooCommerce customer if we have a customer ID
      if (customerId != null) {
        final result = await _updateWooCommerceCustomer(customerId, userData);
        if (result['success']) {
          return result;
        } else if (userId != null) {
          // Fall back to WordPress user update if WooCommerce update fails
          return await _updateWordPressUser(userId, userData);
        }
      }
      // Try WordPress update if we have a user ID but no customer ID
      else if (userId != null) {
        return await _updateWordPressUser(userId, userData);
      }

      // If no server updates were possible, return local success
      return {'success': true, 'message': 'Profile updated locally'};
    } catch (e) {
      print('Error in updateUserProfile: $e');
      return {
        'success': false,
        'error': 'An error occurred while updating profile',
      };
    }
  }

  // Update WooCommerce customer data
  Future<Map<String, dynamic>> _updateWooCommerceCustomer(
    String customerId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final url = Uri.parse(
        ApiConfig.buildUrl("${ApiConfig.customersEndpoint}/$customerId"),
      );

      // Prepare customer data
      final updateData = _prepareCustomerData(userData);

      // Get authentication headers
      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      final headers = await _apiClient.getAuthHeaders(
        includeWooAuth: true,
        authToken: authToken,
        basicAuth: basicAuth,
      );

      // Debug info
      print("Updating customer with URL: $url");
      print("Update data: ${json.encode(updateData)}");

      // Send update request
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

        return {
          'success': false,
          'message': 'Failed to update customer on server, but saved locally',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      print("Error updating customer profile: $e");
      return {
        'success': false,
        'message': 'Profile updated locally. Server sync failed.',
        'error': e.toString(),
      };
    }
  }

  // Update WordPress user data
  Future<Map<String, dynamic>> _updateWordPressUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      final headers = await _apiClient.getAuthHeaders(
        authToken: authToken,
        basicAuth: basicAuth,
      );
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
        return {
          'success': true,
          'message':
              'Profile updated locally. Changes may not sync with server.',
        };
      }
    } catch (e) {
      print("Error updating WordPress user profile: $e");
      return {
        'success': true,
        'message': 'Profile updated locally. Server sync failed.',
      };
    }
  }

  // Helper method to prepare customer data for WooCommerce API
  Map<String, dynamic> _prepareCustomerData(Map<String, dynamic> userData) {
    // Extract name components
    String firstName = userData['first_name'] ?? '';
    String lastName = userData['last_name'] ?? '';

    // If first/last names not provided but full name is available
    if ((firstName.isEmpty || lastName.isEmpty) && userData['name'] != null) {
      String fullName = userData['name'] ?? '';
      if (fullName.contains(' ')) {
        final nameParts = fullName.split(' ');
        if (firstName.isEmpty) firstName = nameParts.first;
        if (lastName.isEmpty) lastName = nameParts.sublist(1).join(' ');
      } else if (firstName.isEmpty) {
        firstName = fullName;
      }
    }

    // Parse address into components if available
    Map<String, String> addressComponents = {};
    if (userData['address'] != null &&
        userData['address'].toString().isNotEmpty) {
      addressComponents = _parseAddressString(userData['address']);
    }

    // Create properly structured update payload
    final Map<String, dynamic> customerData = {
      'first_name': firstName,
      'last_name': lastName,
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'phone': userData['phone'] ?? '',
        'email': userData['email'] ?? '',
      },
      'shipping': {'first_name': firstName, 'last_name': lastName},
    };

    // Add address components if available
    if (addressComponents.isNotEmpty) {
      customerData['billing']['address_1'] = addressComponents['street'] ?? '';
      customerData['billing']['city'] = addressComponents['city'] ?? '';
      customerData['billing']['state'] = addressComponents['state'] ?? '';
      customerData['billing']['postcode'] =
          addressComponents['postalCode'] ?? '123456';
      customerData['billing']['country'] = addressComponents['country'] ?? 'IN';

      // Also update shipping address
      customerData['shipping']['address_1'] = addressComponents['street'] ?? '';
      customerData['shipping']['city'] = addressComponents['city'] ?? '';
      customerData['shipping']['state'] = addressComponents['state'] ?? '';
      customerData['shipping']['postcode'] =
          addressComponents['postalCode'] ?? '123456';
      customerData['shipping']['country'] =
          addressComponents['country'] ?? 'IN';
    } else {
      // Add default values if no address components
      customerData['billing']['address_1'] = 'Default Address';
      customerData['billing']['city'] = 'Default City';
      customerData['billing']['state'] = 'Default State';
      customerData['billing']['postcode'] = '123456';
      customerData['billing']['country'] = 'IN';

      customerData['shipping']['address_1'] = 'Default Address';
      customerData['shipping']['city'] = 'Default City';
      customerData['shipping']['state'] = 'Default State';
      customerData['shipping']['postcode'] = '123456';
      customerData['shipping']['country'] = 'IN';
    }

    return customerData;
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

  // Get user profile details from server or local storage
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userInfo = await getCurrentUser();

      print("DEBUG - getUserProfile - User Info: $userInfo");

      if (!userInfo["logged_in"]) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Get user ID and customer ID
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
        final customerProfile = await _getWooCommerceCustomerProfile(
          customerId.toString(),
        );
        if (customerProfile['success']) {
          return customerProfile;
        }
      }

      // Fall back to WordPress user data
      if (userId != null) {
        final wpProfile = await _getWordPressUserProfile(userId.toString());
        if (wpProfile['success']) {
          return wpProfile;
        }
      }

      // If all else fails, return the current user data we have
      return {'success': true, 'data': userInfo};
    } catch (e) {
      print("Error in getUserProfile: $e");
      return {'success': false, 'error': 'Failed to get user profile: $e'};
    }
  }

  // Get customer profile from WooCommerce
  Future<Map<String, dynamic>> _getWooCommerceCustomerProfile(
    String customerId,
  ) async {
    try {
      final url = Uri.parse(
        ApiConfig.buildUrl("${ApiConfig.customersEndpoint}/$customerId"),
      );

      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      final headers = await _apiClient.getAuthHeaders(
        includeWooAuth: true,
        authToken: authToken,
        basicAuth: basicAuth,
      );

      print("DEBUG - Fetching WooCommerce profile - URL: $url");
      print(
        "DEBUG - Fetching WooCommerce profile - auth token exists: ${authToken != null}",
      );

      final response = await http.get(url, headers: headers);

      print(
        "DEBUG - WooCommerce profile response status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final customerData = json.decode(response.body);
        return {'success': true, 'data': customerData};
      }
      // Handle 401/403 by returning failure, but don't log the user out
      else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
          "Authentication issue when fetching WooCommerce customer profile: ${response.statusCode}",
        );
        return {'success': false, 'auth_error': true};
      }

      return {'success': false};
    } catch (e) {
      print("Error getting customer profile: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user profile from WordPress
  Future<Map<String, dynamic>> _getWordPressUserProfile(String userId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/wp/v2/users/$userId");

      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      final headers = await _apiClient.getAuthHeaders(
        authToken: authToken,
        basicAuth: basicAuth,
      );

      print("DEBUG - Fetching WordPress profile - URL: $url");

      final response = await http.get(url, headers: headers);

      print(
        "DEBUG - WordPress profile response status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {'success': true, 'data': userData};
      }
      // Handle 401/403 by returning failure, but don't log the user out
      else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
          "Authentication issue when fetching WordPress user profile: ${response.statusCode}",
        );
        return {'success': false, 'auth_error': true};
      }

      return {'success': false};
    } catch (e) {
      print("Error getting WordPress user profile: $e");
      return {'success': false, 'error': e.toString()};
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

  // Get orders for current user
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

      // Check if this is a local user without server sync
      final isLocalUser = userInfo["local_only"] == true;
      if (isLocalUser && userInfo["customer_id"] == null) {
        print("Local user without customer ID - returning empty orders list");
        return [];
      }

      // Build query parameters
      final queryParams = _buildOrdersQueryParams(
        page,
        perPage,
        status,
        userInfo,
      );

      if (queryParams.isEmpty) {
        return [];
      }

      // Make authenticated request to get orders
      return await _fetchOrders(queryParams);
    } catch (e) {
      print("Error in getOrders: $e");
      return [];
    }
  }

  // Build query parameters for orders request
  Map<String, dynamic> _buildOrdersQueryParams(
    int page,
    int perPage,
    String status,
    Map<String, dynamic> userInfo,
  ) {
    Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != 'any') {
      queryParams['status'] = status;
    }

    // Add customer ID or user ID to the query
    if (userInfo["customer_id"] != null) {
      queryParams['customer'] = userInfo["customer_id"].toString();
    } else if (userInfo["user_id"] != null) {
      queryParams['user_id'] = userInfo["user_id"].toString();
    } else {
      print(
        "No customer ID or user ID available - returning empty orders list",
      );
      return {};
    }

    return queryParams;
  }

  // Fetch orders from the WooCommerce API
  Future<List<Map<String, dynamic>>> _fetchOrders(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      int? customerId = await _storage.getCustomerId();

      final response = await _apiClient.authenticatedRequest(
        ApiConfig.ordersEndpoint,
        method: 'GET',
        queryParams: queryParams,
        timeoutSeconds: 10,
        authToken: authToken,
        basicAuth: basicAuth,
        customerId: customerId,
      );

      if (response.statusCode == 200) {
        List<dynamic> orders = json.decode(response.body);
        return orders.cast<Map<String, dynamic>>();
      } else {
        print("Failed to fetch orders: ${response.statusCode}");
        // Don't log the user out for API failures
        return [];
      }
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  // Get count of user's orders
  Future<int> getOrderCount() async {
    try {
      // Check login status
      final userInfo = await getCurrentUser();
      if (!userInfo["logged_in"]) {
        return 0;
      }

      // Check if this is a local user
      final isLocalUser = userInfo["local_only"] == true;
      if (isLocalUser && userInfo["customer_id"] == null) {
        return 0;
      }

      // If no customer ID, return 0
      if (userInfo["customer_id"] == null) {
        return 0;
      }

      // Build query for just 1 order to check if any exist
      Map<String, dynamic> queryParams = {
        'page': '1',
        'per_page': '1',
        'customer': userInfo["customer_id"].toString(),
      };

      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      int? customerId = await _storage.getCustomerId();

      final response = await _apiClient.authenticatedRequest(
        ApiConfig.ordersEndpoint,
        method: 'GET',
        queryParams: queryParams,
        authToken: authToken,
        basicAuth: basicAuth,
        customerId: customerId,
      );

      if (response.statusCode == 200) {
        // Check if the total count is in the headers
        final totalCountHeader = response.headers['x-wp-total'];
        if (totalCountHeader != null) {
          return int.tryParse(totalCountHeader) ?? 0;
        }

        // If no header, check if array has items
        List<dynamic> orders = json.decode(response.body);
        return orders.isEmpty ? 0 : 1;
      }
      // Don't log the user out for API failures
      return 0;
    } catch (e) {
      print("Error in getOrderCount: $e");
      return 0;
    }
  }

  // Check if user is a new customer with no orders
  Future<bool> isNewCustomer() async {
    final userInfo = await getCurrentUser();
    if (userInfo["local_only"] == true) {
      return true;
    }

    final orderCount = await getOrderCount();
    return orderCount == 0;
  }

  // Get single order by ID
  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      String? authToken = await _storage.getAuthToken();
      String? basicAuth = await _storage.getBasicAuth();
      int? customerId = await _storage.getCustomerId();

      final response = await _apiClient.authenticatedRequest(
        "${ApiConfig.ordersEndpoint}/$orderId",
        method: 'GET',
        authToken: authToken,
        basicAuth: basicAuth,
        customerId: customerId,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch order #$orderId: ${response.statusCode}");
        // Don't log the user out for API failures
        return null;
      }
    } catch (e) {
      print("Error fetching order #$orderId: $e");
      return null;
    }
  }
}
