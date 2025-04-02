class ApiConfig {
  // Base URL for all API calls
  static const String baseUrl = "https://map.uminber.in/wp-json";

  // WooCommerce authentication credentials
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  // Common API endpoints
  static const String authEndpoint = "/jwt-auth/v1/token";
  static const String productsEndpoint = "/wc/v3/products";
  static const String categoriesEndpoint = "/wc/v3/products/categories";
  static const String customersEndpoint = "/wc/v3/customers";
  static const String ordersEndpoint = "/wc/v3/orders";

  // Media endpoint for fetching banners
  static const String mediaEndpoint = "/wp/v2/media";

  // Remove the incorrect bannersEndpoint with duplicate /wp-json path
  // static const String bannersEndpoint = "/wp-json/trueway/v1/banners";

  // Helper method to build a full URL with auth parameters
  static String buildUrl(String endpoint, {Map<String, dynamic>? queryParams}) {
    String url = baseUrl + endpoint;
    String separator = endpoint.contains("?") ? "&" : "?";
    url +=
        "${separator}consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    // Add any additional query parameters
    if (queryParams != null && queryParams.isNotEmpty) {
      queryParams.forEach((key, value) {
        url += "&$key=$value";
      });
    }

    return url;
  }
}
