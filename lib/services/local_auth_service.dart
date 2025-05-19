// local_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// A service that handles authentication locally when server registration fails
class LocalAuthService {
  static const String _usersKey = 'local_users';
  static const String _currentUserKey = 'current_local_user';
  
  /// Register a new user locally
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users or create empty list
      final String? usersJson = prefs.getString(_usersKey);
      List<Map<String, dynamic>> users = [];
      
      if (usersJson != null) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        users = decoded.cast<Map<String, dynamic>>();
      }
      
      // Check if email already exists
      final existingUser = users.where((user) => user['email'] == email).toList();
      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'error': 'Email already registered locally. Please login instead.'
        };
      }
      
      // Hash the password for security
      final String hashedPassword = _hashPassword(password);
      
      // Create new user object with generated ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = {
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'mobile': mobile,
        'password_hash': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
        'is_local': true
      };
      
      // Add to users list and save
      users.add(newUser);
      await prefs.setString(_usersKey, jsonEncode(users));
      
      // Set as current user
      await prefs.setString(_currentUserKey, jsonEncode(newUser));
      
      return {
        'success': true,
        'message': 'Registration successful (Local Mode)',
        'user': {
          'id': userId, 
          'email': email,
          'name': '$firstName $lastName',
          'is_local': true
        }
      };
    } catch (e) {
      debugPrint('Error in local registration: $e');
      return {
        'success': false,
        'error': 'Failed to register locally: $e'
      };
    }
  }
  
  /// Login a user with local credentials
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final String? usersJson = prefs.getString(_usersKey);
      if (usersJson == null) {
        return {
          'success': false,
          'error': 'No local users found. Please register first.'
        };
      }
      
      final List<dynamic> decoded = jsonDecode(usersJson);
      final List<Map<String, dynamic>> users = decoded.cast<Map<String, dynamic>>();
      
      // Find user by email
      final matchingUsers = users.where((user) => user['email'] == email).toList();
      if (matchingUsers.isEmpty) {
        return {
          'success': false,
          'error': 'Email not found. Please register first.'
        };
      }
      
      final user = matchingUsers.first;
      
      // Verify password
      final String hashedInputPassword = _hashPassword(password);
      if (hashedInputPassword != user['password_hash']) {
        return {
          'success': false,
          'error': 'Incorrect password. Please try again.'
        };
      }
      
      // Set as current user
      await prefs.setString(_currentUserKey, jsonEncode(user));
      
      return {
        'success': true,
        'message': 'Login successful (Local Mode)',
        'user': {
          'id': user['id'], 
          'email': user['email'],
          'name': '${user['first_name']} ${user['last_name']}',
          'is_local': true
        }
      };
    } catch (e) {
      debugPrint('Error in local login: $e');
      return {
        'success': false,
        'error': 'Failed to login locally: $e'
      };
    }
  }
  
  /// Check if a user is currently logged in locally
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentUserKey) != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get current logged in user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_currentUserKey);
      
      if (userJson == null) return null;
      
      final Map<String, dynamic> user = jsonDecode(userJson);
      return {
        'id': user['id'], 
        'email': user['email'],
        'name': '${user['first_name']} ${user['last_name']}',
        'mobile': user['mobile'],
        'is_local': true
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Logout current user
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Hash a password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
