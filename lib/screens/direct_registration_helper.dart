import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueway_ecommerce/providers/auth_provider.dart';
import 'package:trueway_ecommerce/screens/main_screen.dart';

/// A utility class for handling user registration when server registration fails
class DirectRegistrationHelper {
  /// Register a user locally when server registration fails
  static Future<bool> registerUserLocally(
    BuildContext context, {
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      // Create a user ID from timestamp
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create a user data map
      final userData = {
        'id': userId,
        'user_id': userId,
        'email': email,
        'name': '$firstName $lastName',
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'phone': mobile,
        'is_local_user': true,
      };
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      await prefs.setString('user_${userId}_name', '$firstName $lastName');
      await prefs.setString('user_${userId}_email', email);
      await prefs.setString('user_${userId}_phone', mobile);
      
      // Also save as JSON
      await prefs.setString('user_data_$userId', jsonEncode(userData));
      
      // Save credentials separately (for manual login)
      await prefs.setString('local_user_email', email);
      await prefs.setString('local_user_password', password);
      
      // Flag this as a local-only registration
      await prefs.setBool('is_local_user', true);
      
      // Update the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateCurrentUser(userData);
      
      return true;
    } catch (e) {
      print('Error registering user locally: $e');
      return false;
    }
  }
  
  /// Show a dialog to offer local registration when server registration fails
  static Future<bool> showLocalRegistrationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Server Registration Failed'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The app couldn\'t connect to the server. Would you like to create a local account instead?',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Account Limitations:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Works only on this device\n'
                          '• Data won\'t sync with the server\n'
                          '• Some features may be limited',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Create Local Account'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
  
  /// Complete direct registration flow with local fallback
  static Future<Map<String, dynamic>> completeRegistration(
    BuildContext context, {
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      // Create a local account
      final success = await registerUserLocally(
        context,
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        password: password,
      );
      
      if (success) {
        // Navigate to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
        
        return {
          'success': true,
          'message': 'Local account created successfully',
          'is_local': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create local account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }
}
