import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueway_ecommerce/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic> _currentUser = {};

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic> get currentUser => _currentUser;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _apiService.isLoggedIn();

      if (_isLoggedIn) {
        // Get user from API
        final apiUser = await _apiService.getCurrentUser();
        if (apiUser.isNotEmpty) {
          _currentUser = apiUser;

          // Ensure we have an ID field - map user_id to id if needed
          if (!_currentUser.containsKey('id') &&
              _currentUser.containsKey('user_id')) {
            _currentUser['id'] = _currentUser['user_id'];
          }
        }

        // Load saved user data if API didn't return complete information
        if (_currentUser.isEmpty || !_currentUser.containsKey('email')) {
          await _loadSavedUserData();
        } else {
          // Store current user data in SharedPreferences
          await _saveUserData(_currentUser);
        }
      } else {
        // Reset user data
        _currentUser = {};
      }
    } catch (e) {
      print('Error checking login status: $e');
      _isLoggedIn = false;
      _currentUser = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSavedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current user ID
      final userId = prefs.getString('current_user_id');

      if (userId != null && userId.isNotEmpty) {
        // Load saved user data
        final name = prefs.getString('user_${userId}_name') ?? '';
        final email = prefs.getString('user_${userId}_email') ?? '';

        // Only update if we have meaningful data
        if (email.isNotEmpty) {
          _currentUser = {'id': userId, 'name': name, 'email': email};
        }
      }
    } catch (e) {
      print('Error loading saved user data: $e');
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      if (userData.isEmpty) {
        print('Cannot save empty user data');
        return;
      }

      // Ensure we have an ID - this is critical
      String userId = '';
      if (userData.containsKey('id') && userData['id'] != null) {
        userId = userData['id'].toString();
      } else if (userData.containsKey('user_id') &&
          userData['user_id'] != null) {
        // Try to use user_id if id is not available
        userId = userData['user_id'].toString();
        userData['id'] = userData['user_id']; // Add id field for consistency
      }

      if (userId.isEmpty) {
        print('Warning: Cannot save user data - no user ID');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Save current user ID for session tracking
      await prefs.setString('current_user_id', userId);

      // Save email if available
      if (userData.containsKey('email') && userData['email'] != null) {
        String email = userData['email'].toString();
        await prefs.setString('user_${userId}_email', email);
      }

      // Save name if available
      if (userData.containsKey('name') && userData['name'] != null) {
        String name = userData['name'].toString();
        await prefs.setString('user_${userId}_name', name);
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Clear all user data EXCEPT for the specified user
  Future<void> clearAllUserDataExcept(String currentUserId) async {
    if (currentUserId.isEmpty) {
      print('Warning: Cannot clear data without valid user ID');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys
      final keys = prefs.getKeys().toList();

      // Clear all 'user_' prefixed keys that don't belong to current user
      for (var key in keys) {
        if (key.startsWith('user_') &&
            !key.startsWith('user_${currentUserId}_') &&
            key != 'user_name' &&
            key != 'user_email' &&
            key != 'user_phone' &&
            key != 'user_address') {
          await prefs.remove(key);
          print('Cleared other user data: $key');
        }
      }

      // Remove legacy keys
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_address');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Email and password are required'};
      }

      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        _isLoggedIn = true;

        // Store email immediately as it's a critical piece of information
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_login_email', email);

        try {
          // Get current user data from API
          final apiUser = await _apiService.getCurrentUser();
          if (apiUser.isNotEmpty) {
            _currentUser = apiUser;
          } else {
            _currentUser = {};
          }

          // Ensure we have a user ID - generate one from email if needed
          if (!_currentUser.containsKey('id') &&
              !_currentUser.containsKey('user_id')) {
            String tempUserId = email.hashCode.toString();
            _currentUser['id'] = tempUserId;
            print('Generated ID from email: $tempUserId');
          } else if (!_currentUser.containsKey('id') &&
              _currentUser.containsKey('user_id')) {
            // Map user_id to id if needed
            _currentUser['id'] = _currentUser['user_id'];
          }

          // Store user ID now that we're sure we have one
          final userId = _currentUser['id'].toString();

          // Clear other users' data but keep this user's data
          await clearAllUserDataExcept(userId);

          // Ensure email is in user data
          if (!_currentUser.containsKey('email') ||
              _currentUser['email'] == null) {
            _currentUser['email'] = email;
          }

          // Generate name from email if none available
          if (!_currentUser.containsKey('name') ||
              _currentUser['name'] == null ||
              _currentUser['name'].toString().isEmpty) {
            String defaultName = email.split('@').first;
            defaultName = defaultName
                .split('.')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '',
                )
                .join(' ');
            _currentUser['name'] = defaultName;
          }

          // Save complete user data
          await _saveUserData(_currentUser);

          print(
            'Logged in as: ${_currentUser['name']} (${_currentUser['email']})',
          );
        } catch (userError) {
          print('Error getting user data: $userError');
          // Create minimal user data if API fails
          _currentUser = {
            'id': email.hashCode.toString(),
            'email': email,
            'name': email.split('@').first,
          };
          await _saveUserData(_currentUser);
        }
      }

      return response;
    } catch (e) {
      print('Error during login: $e');
      return {'success': false, 'message': 'Login error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this new method to the AuthProvider class

  Future<Map<String, dynamic>> signupBasic(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (firstName.isEmpty ||
          lastName.isEmpty ||
          mobile.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      // Combine first and last name for display
      String fullName = "$firstName $lastName".trim();

      // Call the new API method
      final response = await _apiService.signupBasic(
        firstName,
        lastName,
        mobile,
        email,
        password,
      );

      if (response['success'] == true) {
        _isLoggedIn = await _apiService.isLoggedIn();

        if (_isLoggedIn) {
          try {
            // Get user data from API
            final apiUser = await _apiService.getCurrentUser();
            if (apiUser.isNotEmpty) {
              _currentUser = apiUser;
            } else {
              _currentUser = {};
            }

            // Ensure we have a user ID
            if (!_currentUser.containsKey('id') &&
                !_currentUser.containsKey('user_id')) {
              _currentUser['id'] = email.hashCode.toString();
            } else if (!_currentUser.containsKey('id') &&
                _currentUser.containsKey('user_id')) {
              // Map user_id to id if needed
              _currentUser['id'] = _currentUser['user_id'];
            }

            final userId = _currentUser['id'].toString();

            // Clear other users' data
            await clearAllUserDataExcept(userId);

            // Make sure name, email, and phone are set
            _currentUser['name'] = fullName;
            _currentUser['first_name'] = firstName;
            _currentUser['last_name'] = lastName;
            _currentUser['email'] = email;
            _currentUser['phone'] = mobile;

            // Save user data
            await _saveUserData(_currentUser);

            // Save email for future reference
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_login_email', email);
            await prefs.setString('user_phone', mobile);
          } catch (userError) {
            print('Error getting user data after signup: $userError');
            // Create minimal user data
            _currentUser = {
              'id': email.hashCode.toString(),
              'name': fullName,
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'phone': mobile,
            };
            await _saveUserData(_currentUser);
          }
        }
      }

      return response;
    } catch (e) {
      print('Error during signup: $e');
      return {'success': false, 'message': 'Signup error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isLoggedIn) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Call the API service to get the profile data
      final response = await _apiService.getUserProfile();

      if (response['success'] && response['data'] != null) {
        // Update the current user data with the profile information
        final profileData = response['data'];

        // Merge with existing user data, keeping the ID consistent
        Map<String, dynamic> updatedUser = {..._currentUser, ...profileData};

        // Make sure we don't lose the ID
        if (!updatedUser.containsKey('id') && _currentUser.containsKey('id')) {
          updatedUser['id'] = _currentUser['id'];
        }

        // Fix for user_id field mapping
        if (!updatedUser.containsKey('id') &&
            updatedUser.containsKey('user_id')) {
          updatedUser['id'] = updatedUser['user_id'];
        }

        _currentUser = updatedUser;

        // Save updated user data
        await _saveUserData(_currentUser);
      }

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return {'success': false, 'error': 'Failed to load profile: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Updated logout method to return response format expected by ProfileScreen
  Future<Map<String, dynamic>> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.logout();

      // Clear session data
      final prefs = await SharedPreferences.getInstance();

      // Clear session tracking
      await prefs.remove('current_user_id');

      // Remove old non-prefixed keys that might cause issues
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_address');

      _isLoggedIn = false;
      _currentUser = {};

      return response; // Now using the response from ApiService
    } catch (e) {
      print('Error during logout: $e');
      return {'success': false, 'error': 'Error during logout: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update current user data
  Future<void> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      if (userData.isEmpty) {
        print('Cannot update with empty user data');
        return;
      }

      // Get the current state first
      Map<String, dynamic> updatedUser = Map.from(_currentUser);

      // Make sure we don't lose any IDs when updating
      if (_currentUser.containsKey('id') && !userData.containsKey('id')) {
        userData['id'] = _currentUser['id'];
      }

      if (_currentUser.containsKey('user_id') &&
          !userData.containsKey('user_id')) {
        userData['user_id'] = _currentUser['user_id'];
      }

      if (_currentUser.containsKey('customer_id') &&
          !userData.containsKey('customer_id')) {
        userData['customer_id'] = _currentUser['customer_id'];
      }

      // Update with new values
      updatedUser.addAll(userData);

      // Ensure all IDs are strings
      if (updatedUser.containsKey('id')) {
        updatedUser['id'] = updatedUser['id'].toString();
      }

      if (updatedUser.containsKey('user_id')) {
        updatedUser['user_id'] = updatedUser['user_id'].toString();
      }

      if (updatedUser.containsKey('customer_id')) {
        updatedUser['customer_id'] = updatedUser['customer_id'].toString();
      }

      // Update current user data
      _currentUser = updatedUser;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String userId = '';

      // Get user ID from the updated data
      if (updatedUser.containsKey('id') && updatedUser['id'] != null) {
        userId = updatedUser['id'].toString();
      } else if (updatedUser.containsKey('user_id') &&
          updatedUser['user_id'] != null) {
        userId = updatedUser['user_id'].toString();
        // Ensure we have 'id' field for consistency
        updatedUser['id'] = userId;
        _currentUser['id'] = userId;
      } else if (updatedUser.containsKey('customer_id') &&
          updatedUser['customer_id'] != null) {
        // Last resort - use customer_id if no user_id
        userId = updatedUser['customer_id'].toString();
        // Don't set as 'id' to avoid confusion
      }

      if (userId.isEmpty) {
        print('Warning: Cannot save user data - no user ID found');
        return;
      }

      // Save current user ID
      await prefs.setString('current_user_id', userId);

      // Save user data
      if (updatedUser.containsKey('name') && updatedUser['name'] != null) {
        await prefs.setString(
          'user_${userId}_name',
          updatedUser['name'].toString(),
        );
      }

      if (updatedUser.containsKey('email') && updatedUser['email'] != null) {
        await prefs.setString(
          'user_${userId}_email',
          updatedUser['email'].toString(),
        );
      }

      if (updatedUser.containsKey('phone') && updatedUser['phone'] != null) {
        await prefs.setString(
          'user_${userId}_phone',
          updatedUser['phone'].toString(),
        );
      }

      if (updatedUser.containsKey('address') &&
          updatedUser['address'] != null) {
        await prefs.setString(
          'user_${userId}_address',
          updatedUser['address'].toString(),
        );
      }

      // Save to old format keys too for backward compatibility
      await prefs.setString('user_name', updatedUser['name'] ?? '');
      await prefs.setString('user_email', updatedUser['email'] ?? '');
      if (updatedUser.containsKey('phone')) {
        await prefs.setString('user_phone', updatedUser['phone'].toString());
      }
      if (updatedUser.containsKey('address')) {
        await prefs.setString(
          'user_address',
          updatedUser['address'].toString(),
        );
      }

      // Save IDs if available
      if (updatedUser.containsKey('user_id') &&
          updatedUser['user_id'] != null) {
        // Convert string to int if needed
        int? userIdInt;
        if (updatedUser['user_id'] is String) {
          userIdInt = int.tryParse(updatedUser['user_id']);
        } else {
          userIdInt = updatedUser['user_id'] as int?;
        }

        if (userIdInt != null) {
          await prefs.setInt('user_id', userIdInt);
        }
      }

      if (updatedUser.containsKey('customer_id') &&
          updatedUser['customer_id'] != null) {
        // Convert string to int if needed
        int? customerIdInt;
        if (updatedUser['customer_id'] is String) {
          customerIdInt = int.tryParse(updatedUser['customer_id']);
        } else {
          customerIdInt = updatedUser['customer_id'] as int?;
        }

        if (customerIdInt != null) {
          await prefs.setInt('customer_id', customerIdInt);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error updating current user data: $e');
    }
  }

  // Refresh user data with extra validation
  Future<void> refreshUser() async {
    if (!_isLoggedIn) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Make sure we have a user ID
      if (!_currentUser.containsKey('id') &&
          !_currentUser.containsKey('user_id')) {
        print('Cannot refresh user: No user ID available');
        return;
      }

      // Get user ID - use either id or user_id field
      final userId =
          _currentUser.containsKey('id')
              ? _currentUser['id'].toString()
              : _currentUser['user_id'].toString();

      // Verify session matches current user
      final prefs = await SharedPreferences.getInstance();
      final currentSessionId = prefs.getString('current_user_id');

      if (currentSessionId != userId) {
        print('Session mismatch - updating session ID');
        await prefs.setString('current_user_id', userId);
      }

      // Get fresh data from API
      final apiUser = await _apiService.getCurrentUser();

      if (apiUser.isNotEmpty) {
        // Make sure we don't lose ID or email
        if (!apiUser.containsKey('id') && !apiUser.containsKey('user_id')) {
          apiUser['id'] = userId;
        } else if (!apiUser.containsKey('id') &&
            apiUser.containsKey('user_id')) {
          apiUser['id'] = apiUser['user_id'];
        }

        if (!apiUser.containsKey('email') &&
            _currentUser.containsKey('email')) {
          apiUser['email'] = _currentUser['email'];
        }

        _currentUser = apiUser;
        await _saveUserData(_currentUser);
      } else {
        // API returned no data, load from saved data
        await _loadSavedUserData();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
