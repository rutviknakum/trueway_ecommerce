import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = 'Guest';
  String _email = '';
  String _profileImageUrl = '';
  bool _isLoggedIn = false;

  // Getters
  String get username => _username;
  String get email => _email;
  String get profileImageUrl => _profileImageUrl;
  bool get isLoggedIn => _isLoggedIn;

  // Method to set user data on login
  Future<void> login(
    String username,
    String email,
    String profileImageUrl,
  ) async {
    _username = username;
    _email = email;
    _profileImageUrl = profileImageUrl;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Method to clear user data on logout
  Future<void> logout() async {
    _username = 'Guest';
    _email = '';
    _profileImageUrl = '';
    _isLoggedIn = false;
    notifyListeners();
  }

  // Method to update user profile
  Future<void> updateProfile(
    Map<String, String> map, {
    String? username,
    String? email,
    String? profileImageUrl,
  }) async {
    if (username != null) _username = username;
    if (email != null) _email = email;
    if (profileImageUrl != null) _profileImageUrl = profileImageUrl;
    notifyListeners();
  }
}
