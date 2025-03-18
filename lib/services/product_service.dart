import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = "https://map.uminber.in/wp-json/wc/v3/products";
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  /// Fetches the list of products from WooCommerce API
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = Uri.parse(
      "$baseUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);

      print("Product Response Code: ${response.statusCode}");
      print("Product Response Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        return products.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          "Failed to load products, Status Code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Product Fetch Error: $e");
      throw Exception("Error fetching products: $e");
    }
  }
}
