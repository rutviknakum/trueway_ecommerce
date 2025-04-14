// api_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

extension ApiProfileService on ApiService {
  // Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // First check if the user is logged in
      bool isLoggedIn = await this.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Get current user info from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("user_email");
      final name = prefs.getString("user_name");

      // Get IDs and store as strings to avoid type issues
      final userId =
          prefs.getString("user_id") ?? prefs.getInt("user_id")?.toString();
      final customerId = prefs.getInt("customer_id")?.toString();

      // Debug information
      print("DEBUG - getUserProfile - email: $email");
      print("DEBUG - getUserProfile - name: $name");
      print("DEBUG - getUserProfile - userId: $userId");
      print("DEBUG - getUserProfile - customerId: $customerId");

      Map<String, dynamic> userData = {
        'email': email,
        'name': name,
        'user_id': userId,
        'customer_id': customerId,
      };

      // IMPORTANT: Don't clear auth token or auth state!
      // We're just retrieving profile data here.

      // If we have a customer ID, try to get more details from WooCommerce
      if (customerId != null) {
        try {
          final url = Uri.parse(
            ApiConfig.buildUrl("${ApiConfig.customersEndpoint}/$customerId"),
          );

          final headers = await getAuthHeaders(includeWooAuth: true);
          final response = await http.get(url, headers: headers);

          if (response.statusCode == 200) {
            final customerData = json.decode(response.body);

            // Add more user details from the API response
            userData['phone'] = customerData['billing']['phone'] ?? '';
            userData['address'] = _formatAddress(
              customerData['billing']['address_1'] ?? '',
              customerData['billing']['city'] ?? '',
              customerData['billing']['state'] ?? '',
              customerData['billing']['postcode'] ?? '',
              customerData['billing']['country'] ?? '',
            );

            // Extract first and last name if available
            if (customerData['first_name'] != null &&
                customerData['first_name'].isNotEmpty) {
              String fullName = customerData['first_name'];
              if (customerData['last_name'] != null &&
                  customerData['last_name'].isNotEmpty) {
                fullName += " ${customerData['last_name']}";
              }
              userData['name'] = fullName;

              // Update stored name if we got a better one from the API
              await prefs.setString("user_name", fullName);
            }
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Authentication failure when getting customer details
            // This doesn't mean we should log the user out - just continue with basic data
            print(
              "Authentication issue when fetching customer details: ${response.statusCode}",
            );
          }
        } catch (e) {
          print("Error fetching customer details: $e");
          // Continue with basic user data if customer fetch fails
        }
      } else if (userId != null) {
        // Try to get user data from WordPress if no customer ID but we have a user ID
        try {
          final headers = await getAuthHeaders();
          final url = Uri.parse('${ApiConfig.baseUrl}/wp/v2/users/$userId');

          final response = await http.get(url, headers: headers);

          if (response.statusCode == 200) {
            final wpUserData = json.decode(response.body);

            // Update user data with WordPress user info
            if (wpUserData['name'] != null && wpUserData['name'].isNotEmpty) {
              userData['name'] = wpUserData['name'];
              await prefs.setString("user_name", wpUserData['name']);
            }

            // Add any other WordPress user metadata if available
            if (wpUserData['meta'] != null) {
              if (wpUserData['meta']['phone'] != null) {
                userData['phone'] = wpUserData['meta']['phone'];
              }
              if (wpUserData['meta']['address'] != null) {
                userData['address'] = wpUserData['meta']['address'];
              }
            }
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Authentication failure when getting WordPress user details
            // This doesn't mean we should log the user out - just continue with basic data
            print(
              "Authentication issue when fetching WordPress user details: ${response.statusCode}",
            );
          }
        } catch (e) {
          print("Error fetching WordPress user details: $e");
          // Continue with basic user data if WP user fetch fails
        }
      }

      return {'success': true, 'data': userData};
    } catch (e) {
      print('Error in getUserProfile: $e');
      return {
        'success': false,
        'error': 'An error occurred while fetching profile data',
      };
    }
  }

  // Update user profile data
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

      // IMPORTANT: Don't clear auth token or auth state!
      // We're just updating profile data here.

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
          headers['Content-Type'] = 'application/json';

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
            if ((response.statusCode == 403 || response.statusCode == 401) &&
                userId != null) {
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

  // Helper function to format address
  String _formatAddress(
    String street,
    String city,
    String state,
    String postcode,
    String country,
  ) {
    List<String> parts = [];

    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (postcode.isNotEmpty) parts.add(postcode);
    if (country.isNotEmpty) parts.add(country);

    if (parts.isEmpty) return '';
    return parts.join(', ');
  }
}
