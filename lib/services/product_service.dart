import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class ProductService {
  final ApiService _apiService = ApiService();

  /// Fetches all products from WooCommerce API
  Future<List<Map<String, dynamic>>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String? searchQuery,
    int? categoryId,
    String? sortBy,
    bool? featured,
    bool? onSale,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        "page": page.toString(),
        "per_page": perPage.toString(),
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams["search"] = searchQuery;
      }

      if (categoryId != null) {
        queryParams["category"] = categoryId.toString();
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        // Handle different sort options
        if (sortBy == "price-asc") {
          queryParams["orderby"] = "price";
          queryParams["order"] = "asc";
        } else if (sortBy == "price-desc") {
          queryParams["orderby"] = "price";
          queryParams["order"] = "desc";
        } else {
          queryParams["orderby"] = sortBy;
        }
      }

      if (featured != null && featured) {
        queryParams["featured"] = "true";
      }

      if (onSale != null && onSale) {
        queryParams["on_sale"] = "true";
      }

      final response = await _apiService.publicRequest(
        ApiConfig.productsEndpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        return products.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching products: $e");
      throw Exception("Error fetching products: $e");
    }
  }

  /// Fetches a single product by ID
  Future<Map<String, dynamic>> fetchProductById(int productId) async {
    try {
      final response = await _apiService.publicRequest(
        "${ApiConfig.productsEndpoint}/$productId",
        method: 'GET',
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> product = json.decode(response.body);
        return product;
      } else {
        throw Exception("Failed to load product: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching product: $e");
      throw Exception("Error fetching product: $e");
    }
  }

  /// Fetches product categories
  Future<List<Map<String, dynamic>>> fetchCategories({
    int? parent,
    int perPage = 100,
    bool hideEmpty = true,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        "per_page": perPage.toString(),
        "hide_empty": hideEmpty.toString(),
      };

      if (parent != null) {
        queryParams["parent"] = parent.toString();
      }

      final response = await _apiService.publicRequest(
        ApiConfig.categoriesEndpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        List<dynamic> categories = json.decode(response.body);

        return categories.map<Map<String, dynamic>>((category) {
          return {
            "id": category["id"],
            "name": category["name"],
            "count": category["count"] ?? 0,
            "image":
                category["image"] != null ? category["image"]["src"] : null,
            "parent": category["parent"] ?? 0,
          };
        }).toList();
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
      throw Exception("Error fetching categories: $e");
    }
  }

  /// Fetches banner images from WordPress media library
  Future<List<String>> fetchBanners() async {
    try {
      // Direct URL construction to ensure compatibility with your backend
      final url = Uri.parse(
        "${ApiConfig.baseUrl}${ApiConfig.mediaEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}&per_page=10",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> media = json.decode(response.body);
        print("Media response received: ${media.length} items");

        // Extract all image URLs
        List<String> bannerUrls = [];
        for (var item in media) {
          if (item["media_type"] == "image") {
            String sourceUrl = item["source_url"] as String;
            bannerUrls.add(sourceUrl);
            print("Found banner image: $sourceUrl");
          }
        }

        // If we have at least one banner, return the list
        if (bannerUrls.isNotEmpty) {
          return bannerUrls;
        }

        // If no suitable images found, return fallback images
        print("No suitable banner images found in media library");
        return _getFallbackBanners();
      } else {
        print("Failed to load media: ${response.statusCode}");
        // Return fallback banner images
        return _getFallbackBanners();
      }
    } catch (e) {
      print("Error fetching banners: $e");
      // Return fallback banner images
      return _getFallbackBanners();
    }
  }

  /// Provides fallback banner images when API fails
  List<String> _getFallbackBanners() {
    return [
      "https://picsum.photos/800/400?random=1",
      "https://picsum.photos/800/400?random=2",
      "https://picsum.photos/800/400?random=3",
      "https://picsum.photos/800/400?random=4",
      "https://picsum.photos/800/400?random=5",
    ];
  }

  /// Fetches product reviews
  Future<List<Map<String, dynamic>>> fetchProductReviews(int productId) async {
    try {
      final response = await _apiService.publicRequest(
        "/wc/v3/products/reviews",
        method: 'GET',
        queryParams: {"product": productId.toString()},
      );

      if (response.statusCode == 200) {
        List<dynamic> reviews = json.decode(response.body);
        return reviews.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load reviews: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
      throw Exception("Error fetching reviews: $e");
    }
  }

  /// Submits a product review
  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required String review,
    required String reviewer,
    required String reviewerEmail,
    required int rating,
  }) async {
    try {
      final body = {
        "product_id": productId,
        "review": review,
        "reviewer": reviewer,
        "reviewer_email": reviewerEmail,
        "rating": rating,
      };

      final response = await _apiService.authenticatedRequest(
        "/wc/v3/products/reviews",
        method: 'POST',
        body: body,
      );

      if (response.statusCode == 201) {
        return {"success": true, "data": json.decode(response.body)};
      } else {
        return {
          "success": false,
          "error": "Failed to submit review: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Error submitting review: $e");
      return {"success": false, "error": "Error submitting review: $e"};
    }
  }
}
