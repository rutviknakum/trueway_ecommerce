import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = "https://map.uminber.in/wp-json/wc/v3";
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  /// Fetches all products from WooCommerce API
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = Uri.parse(
      "$baseUrl/products?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        return products.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  /// Searches for products based on the query
  static Future<List<Map<String, dynamic>>> searchProducts(
    String query, {
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final url = Uri.parse(
      "$baseUrl/products?search=$query"
      "&consumer_key=$consumerKey&consumer_secret=$consumerSecret"
      "${category != null ? '&category=$category' : ''}"
      "${minPrice != null ? '&min_price=${minPrice.toInt()}' : ''}"
      "${maxPrice != null ? '&max_price=${maxPrice.toInt()}' : ''}",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> products = json.decode(response.body);
      return products.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to search products");
    }
  }

  /// Fetches banner images from WooCommerce API (if using a custom endpoint)
  static Future<List<String>> fetchBanners() async {
    final url = Uri.parse(
      "https://map.uminber.in/wp-json/wp/v2/media?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> banners = json.decode(response.body);
        return banners
            .where((banner) => banner["media_type"] == "image")
            .map<String>((banner) => banner["source_url"] as String)
            .toList();
      } else {
        throw Exception("Failed to load banners");
      }
    } catch (e) {
      throw Exception("Error fetching banners: $e");
    }
  }

  /// Fetches product categories dynamically
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final url = Uri.parse(
      "$baseUrl/products/categories?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> categories = json.decode(response.body);

        return categories.map<Map<String, dynamic>>((category) {
          return {
            "id": category["id"],
            "name": category["name"],
            "image":
                category["image"] != null
                    ? category["image"]["src"]
                    : "https://via.placeholder.com/50",
          };
        }).toList();
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      throw Exception("Error fetching categories: $e");
    }
  }

  /// Fetches products by category ID
  static Future<List<Map<String, dynamic>>> fetchProductsByCategory(
    int categoryId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/products?category=$categoryId&consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Check if response is null or empty
        if (decodedResponse == null || decodedResponse.isEmpty) {
          throw Exception("No products found for this category");
        }

        List<dynamic> products = decodedResponse;

        return products.map<Map<String, dynamic>>((product) {
          return {
            "id": product["id"] ?? 0,
            "name": product["name"] ?? "No Name",
            "price": product["price"]?.toString() ?? "0",
            "image":
                (product["images"] != null && product["images"].isNotEmpty)
                    ? product["images"][0]["src"]
                    : "https://via.placeholder.com/150", // Default image
          };
        }).toList();
      } else {
        throw Exception(
          "Failed to load products. Status Code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error loading products: $e");
    }
  }
}
