// api_service.dart
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'user_service.dart';
import 'storage_service.dart';
import 'api_client.dart';

class ApiService {
  AuthService _authService;
  UserService _userService;
  StorageService _storageService;
  ApiClient _apiClient;

  // Constructor with initialization
  ApiService()
    : _storageService = StorageService(),
      _apiClient = ApiClient(),
      // Initialize with temporary instances
      _authService = AuthService(StorageService()),
      _userService = UserService(StorageService(), ApiClient()) {
    // Fix circular references after initializing
    _authService = AuthService(_storageService);
    _userService = UserService(_storageService, _apiClient);
  }

  // Initialize services
  Future<void> init() async {
    await _storageService.init();

    // Check if we have user data without a user ID and clean it
    await _ensureUserDataConsistency();

    // Reinitialize the services with the properly initialized storage
    _authService = AuthService(_storageService);
    _userService = UserService(_storageService, _apiClient);
  }

  // Ensure user data consistency
  Future<void> _ensureUserDataConsistency() async {
    // Check if we have user data but no user ID
    final userEmail = await _storageService.getUserEmail();
    final userId = await _storageService.getUserId();
    final currentUserId = await _storageService.getCurrentUserId();

    // If we have email but no user ID, generate one
    if (userEmail != null &&
        userEmail.isNotEmpty &&
        (userId == null || currentUserId == null)) {
      print("Found user email without ID. Generating temporary ID.");
      // Generate a hash-based ID from the email
      final generatedId = userEmail.hashCode.toString();
      await _storageService.setUserId(generatedId);
      await _storageService.setCurrentUserId(generatedId);
      print("Set temporary user ID: $generatedId");
    }

    // If we have nothing or have both email and ID, we're good
  }

  // Forgot password service delegation
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    return await _authService.requestPasswordReset(email);
  }

  // Auth service delegation
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<Map<String, dynamic>> loginWithServer(
    String email,
    String password,
  ) async {
    return await _authService.loginWithServer(email, password);
  }

  Future<Map<String, dynamic>> signupBasic(
    String firstName,
    String lastName,
    String mobile,
    String email,
    String password,
    String postalCode,
  ) async {
    return await _authService.signupBasic(
      firstName,
      lastName,
      mobile,
      email,
      password,
    );
  }

  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  Future<bool> checkIfLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  Future<Map<String, dynamic>> logout() async {
    return await _authService.logout();
  }

  // User service delegation
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _userService.getCurrentUser();
  }

  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    return await _userService.getCurrentUser();
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    return await _userService.updateUserProfile(userData);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    return await _userService.getUserProfile();
  }

  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int perPage = 10,
    String status = 'any',
  }) async {
    return await _userService.getOrders(
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  Future<int> getOrderCount() async {
    return await _userService.getOrderCount();
  }

  Future<bool> isNewCustomer() async {
    return await _userService.isNewCustomer();
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    return await _userService.getOrderById(orderId);
  }

  // Shared HTTP request methods
  Future<Map<String, String>> getAuthHeaders({
    bool includeWooAuth = false,
  }) async {
    String? authToken = await _storageService.getAuthToken();
    String? basicAuth = await _storageService.getBasicAuth();

    return _apiClient.getAuthHeaders(
      includeWooAuth: includeWooAuth,
      authToken: authToken,
      basicAuth: basicAuth,
    );
  }

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

    String? authToken = await _storageService.getAuthToken();
    String? basicAuth = await _storageService.getBasicAuth();
    int? customerId = await _storageService.getCustomerId();

    return await _apiClient.authenticatedRequest(
      endpoint,
      method: method,
      body: body,
      queryParams: queryParams,
      timeoutSeconds: timeoutSeconds,
      authToken: authToken,
      basicAuth: basicAuth,
      customerId: customerId,
    );
  }

  Future<http.Response> publicRequest(
    String endpoint, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    return await _apiClient.publicRequest(
      endpoint,
      method: method,
      body: body,
      queryParams: queryParams,
    );
  }

  // Helper functions
  Future<bool> checkEmailExists(String email) async {
    return await _authService.checkEmailExists(email);
  }

  Future<int?> getCustomerId(String email) async {
    return await _userService.getCustomerId(email);
  }
}
