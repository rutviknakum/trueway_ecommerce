import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trueway_ecommerce/models/search_filter.dart';

class SearchService {
  // API endpoints
  final String baseUrl = "https://map.uminber.in/wp-json/wc/v3/products";
  final String categoryUrl =
      "https://map.uminber.in/wp-json/wc/v3/products/categories";
  final String consumerKey = "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  final String consumerSecret = "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  // Data for filters
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> sortOptions = [
    {'id': 'on_sale', 'name': 'On Sale'},
    {'id': 'featured', 'name': 'Featured'},
    {'id': 'date', 'name': 'Date: Latest'},
    {'id': 'date-asc', 'name': 'Date: Oldest'},
    {'id': 'price', 'name': 'Price: Low to High'},
    {'id': 'price-desc', 'name': 'Price: High to Low'},
    {'id': 'title', 'name': 'Title: A to Z'},
    {'id': 'title-desc', 'name': 'Title: Z to A'},
    {'id': 'menu_order', 'name': 'Menu order'},
    {'id': 'popularity', 'name': 'Popularity'},
    {'id': 'rating', 'name': 'Average Rating'},
    {'id': 'rand', 'name': 'Random'},
  ];

  double minPrice = 0;
  double maxPrice = 5000;

  /// Initialize necessary data for search
  Future<void> initializeData() async {
    await fetchCategories();
    await fetchPriceRange();
  }

  /// Fetches product categories from WooCommerce API
  Future<void> fetchCategories() async {
    final url = Uri.parse(
      "$categoryUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret&per_page=100",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> fetchedCategories = json.decode(response.body);
        categories =
            fetchedCategories
                .map(
                  (cat) => {
                    "id": cat["id"],
                    "name": cat["name"],
                    "count": cat["count"] ?? 0,
                  },
                )
                .toList();
      } else {
        throw Exception("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e) {
      print("Category fetch error: $e");
      rethrow;
    }
  }

  /// Fetch price range from available products
  Future<void> fetchPriceRange() async {
    // This could be improved to actually fetch the min/max product prices
    // For now, we'll use default values
    minPrice = 0;
    maxPrice = 5000;
  }

  /// Search products based on query and filters
  Future<List<dynamic>> searchProducts(
    String query,
    SearchFilter filter,
  ) async {
    final url = Uri.parse(
      "$baseUrl?search=${Uri.encodeComponent(query)}"
      "&consumer_key=$consumerKey&consumer_secret=$consumerSecret"
      "${filter.categoryId != null ? '&category=${filter.categoryId}' : ''}"
      "&min_price=${filter.minPrice.toInt()}"
      "&max_price=${filter.maxPrice.toInt()}"
      "&orderby=${filter.sortOption}"
      "&per_page=50",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);

        // Enhanced filtering to ensure exact matches are prioritized
        List<dynamic> filteredProducts =
            products.where((product) {
              String name = (product['name'] ?? "").toString().toLowerCase();
              String description =
                  (product['description'] ?? "").toString().toLowerCase();
              String shortDescription =
                  (product['short_description'] ?? "").toString().toLowerCase();

              String searchQuery = query.toLowerCase();

              // Exact name match gets highest priority
              if (name == searchQuery) return true;

              // Name contains query
              if (name.contains(searchQuery)) return true;

              // Description or short description contains query
              if (description.contains(searchQuery) ||
                  shortDescription.contains(searchQuery))
                return true;

              // Search in product categories
              if (product['categories'] != null) {
                for (var category in product['categories']) {
                  if ((category['name'] ?? "")
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery)) {
                    return true;
                  }
                }
              }

              // Search in product tags
              if (product['tags'] != null) {
                for (var tag in product['tags']) {
                  if ((tag['name'] ?? "").toString().toLowerCase().contains(
                    searchQuery,
                  )) {
                    return true;
                  }
                }
              }

              return false;
            }).toList();

        // Normalize product data
        List<dynamic> normalizedProducts =
            filteredProducts.map((product) {
              return {
                ...product,
                'name': product['name'] ?? "Unnamed Product",
                'price': product['price'] ?? "0",
                'regular_price':
                    product['regular_price'] ?? product['price'] ?? "0",
                'images': product['images'] ?? [],
                'on_sale': product['on_sale'] ?? false,
              };
            }).toList();

        return normalizedProducts;
      } else {
        throw Exception("API error: ${response.statusCode}");
      }
    } catch (e) {
      print("Search error: $e");
      rethrow;
    }
  }

  /// Build product image widget with cached network image
  Widget buildProductImage(dynamic product) {
    // Check if product has images
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0]['src'] != null) {
      String imageUrl = product['images'][0]['src'];

      // Use CachedNetworkImage for better performance
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
      );
    } else {
      // Placeholder for products without images
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }
}
