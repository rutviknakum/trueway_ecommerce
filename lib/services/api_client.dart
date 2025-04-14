// api_client.dart - Handles HTTP requests
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  // Get authentication headers
  Future<Map<String, String>> getAuthHeaders({
    bool includeWooAuth = false,
    String? authToken,
    String? basicAuth,
  }) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
    };

    try {
      // Add token or basic auth if provided
      if (authToken != null && authToken.isNotEmpty && authToken != 'null') {
        headers["Authorization"] = "Bearer $authToken";
      } else if (basicAuth != null &&
          basicAuth.isNotEmpty &&
          basicAuth != 'null') {
        headers["Authorization"] = basicAuth;
      }

      // For WooCommerce API requests that require consumer key/secret
      if (includeWooAuth) {
        final String consumerKey = ApiConfig.consumerKey;
        final String consumerSecret = ApiConfig.consumerSecret;

        if (consumerKey.isNotEmpty && consumerSecret.isNotEmpty) {
          // If we don't have token auth already, add WooCommerce credentials
          if (!headers.containsKey("Authorization") ||
              headers["Authorization"]!.isEmpty) {
            String credentials = base64Encode(
              utf8.encode('$consumerKey:$consumerSecret'),
            );
            headers['Authorization'] = 'Basic $credentials';
          }

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

  // Authenticated request method
  Future<http.Response> authenticatedRequest(
    String endpoint, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParams,
    int timeoutSeconds = 30,
    String? authToken,
    String? basicAuth,
    int? customerId,
  }) async {
    // Determine if this is a WooCommerce API endpoint
    bool isWooCommerceEndpoint = ApiConfig.isWooCommerceEndpoint(endpoint);

    // Get appropriate auth headers
    Map<String, String> headers = await getAuthHeaders(
      includeWooAuth: isWooCommerceEndpoint,
      authToken: authToken,
      basicAuth: basicAuth,
    );

    // Build URL with customer ID if applicable
    String urlString;
    if (isWooCommerceEndpoint) {
      urlString =
          queryParams != null
              ? ApiConfig.buildUrl(endpoint, queryParams: queryParams)
              : ApiConfig.buildUrl(endpoint);
    } else {
      urlString =
          queryParams != null
              ? ApiConfig.buildUrlWithoutAuth(
                endpoint,
                queryParams: queryParams,
              )
              : ApiConfig.buildUrlWithoutAuth(endpoint);
    }

    // Add customer ID to query if applicable
    if (customerId != null &&
        customerId > 0 &&
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
              .timeout(Duration(seconds: ApiConfig.responseTimeout));
          break;
        case 'POST':
          response = await client
              .post(
                url,
                headers: headers,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: ApiConfig.responseTimeout));
          break;
        case 'PUT':
          response = await client
              .put(
                url,
                headers: headers,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: ApiConfig.responseTimeout));
          break;
        case 'DELETE':
          response = await client
              .delete(url, headers: headers)
              .timeout(Duration(seconds: ApiConfig.responseTimeout));
          break;
        default:
          client.close();
          throw Exception("Unsupported HTTP method: $method");
      }

      // Always close the client
      client.close();

      // Debug response
      print("Response status: ${response.statusCode}");

      // Don't log the entire response body for successful responses to avoid console spam
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

            // Add consumer key and secret to URL if not already present
            String newUrlString = urlString;
            if (!newUrlString.contains("consumer_key=")) {
              String separator = newUrlString.contains("?") ? "&" : "?";
              newUrlString =
                  "$newUrlString${separator}consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}";
            }

            final newUrl = Uri.parse(newUrlString);

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

      // Return a mock response for timeouts and errors rather than throwing
      // This prevents app crashes and allows graceful handling
      if (e is http.ClientException || e is TimeoutException) {
        print("Network error or timeout - returning mock error response");
        return http.Response(
          jsonEncode({
            "error": true,
            "message": "Network error or timeout occurred",
            "exception": e.toString(),
          }),
          503, // Service Unavailable
          headers: {"content-type": "application/json"},
        );
      }

      // For other exceptions, rethrow to maintain compatibility with existing code
      rethrow;
    }
  }

  // Public request method - CORRECTED VERSION
  Future<http.Response> publicRequest(
    String endpoint, {
    required String method,
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    // Determine if this is a WooCommerce API endpoint
    bool isWooCommerceEndpoint = ApiConfig.isWooCommerceEndpoint(endpoint);

    // Build URL with appropriate authentication
    String urlString;
    if (isWooCommerceEndpoint) {
      // For WooCommerce endpoints, include auth
      urlString =
          queryParams != null
              ? ApiConfig.buildUrl(endpoint, queryParams: queryParams)
              : ApiConfig.buildUrl(endpoint);
    } else {
      // For other endpoints, don't include auth
      urlString =
          queryParams != null
              ? ApiConfig.buildUrlWithoutAuth(
                endpoint,
                queryParams: queryParams,
              )
              : ApiConfig.buildUrlWithoutAuth(endpoint);
    }

    final url = Uri.parse(urlString);

    try {
      // Create headers with content type
      Map<String, String> headers = {"Content-Type": "application/json"};

      // Debug information
      print("Sending ${method.toUpperCase()} public request to: $url");
      print("Headers: $headers");

      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          return await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw Exception("Unsupported HTTP method: $method");
      }
    } catch (e) {
      print("Error in public request: $e");

      // Return a mock response for timeouts and errors rather than throwing
      if (e is http.ClientException || e is TimeoutException) {
        print("Network error or timeout - returning mock error response");
        return http.Response(
          jsonEncode({
            "error": true,
            "message": "Network error or timeout occurred",
            "exception": e.toString(),
          }),
          503, // Service Unavailable
          headers: {"content-type": "application/json"},
        );
      }

      rethrow;
    }
  }
}
