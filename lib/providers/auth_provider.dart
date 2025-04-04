import 'package:flutter/material.dart';
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

    _isLoggedIn = await _apiService.isLoggedIn();
    if (_isLoggedIn) {
      _currentUser = await _apiService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.login(email, password);

    if (response['success']) {
      _isLoggedIn = true;
      _currentUser = await _apiService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();

    return response;
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.signup(name, email, password);

    if (response['success']) {
      // Check if user is logged in after signup
      _isLoggedIn = await _apiService.isLoggedIn();
      if (_isLoggedIn) {
        _currentUser = await _apiService.getCurrentUser();
      }
    }

    _isLoading = false;
    notifyListeners();

    return response;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.logout();

    _isLoggedIn = false;
    _currentUser = {};

    _isLoading = false;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_isLoggedIn) {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    }
  }
}
