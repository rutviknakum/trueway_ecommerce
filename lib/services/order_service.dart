import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';

class OrderService {
  final String baseUrl = "https://map.uminber.in/wp-json/wc/v3";
  final String consumerKey = "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  final String consumerSecret = "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  Future<List<dynamic>> fetchOrders() async {
    try {
      final url = Uri.parse(
        "$baseUrl/orders?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
      );

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error fetching orders: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<String?> getCustomerId(String email) async {
    final url = Uri.parse("$baseUrl/customers?email=$email");

    final response = await http.get(
      url,
      headers: {
        "Authorization":
            "Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> customers = jsonDecode(response.body);
      if (customers.isNotEmpty) {
        return customers[0]['id'].toString(); // Get first customer's ID
      }
    }
    return null; // Customer not found
  }

  Future<Map<String, dynamic>?> placeOrder(
    String? customerId,
    List<CartItem> cartItems,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/orders");

      List<Map<String, dynamic>> lineItems =
          cartItems.map((item) {
            return {"product_id": item.id, "quantity": item.quantity};
          }).toList();

      Map<String, dynamic> orderData = {
        if (customerId != null && customerId.isNotEmpty)
          "customer_id": customerId,
        "payment_method": "cod",
        "payment_method_title": "Cash on Delivery",
        "set_paid": false,
        "billing": {
          "first_name": "John",
          "last_name": "Doe",
          "address_1": "123 Street",
          "city": "City",
          "postcode": "12345",
          "country": "IN",
          "email": "johndoe@example.com",
          "phone": "1234567890",
        },
        "shipping": {
          "first_name": "John",
          "last_name": "Doe",
          "address_1": "123 Street",
          "city": "City",
          "postcode": "12345",
          "country": "IN",
        },
        "line_items": lineItems,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}",
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("Order API Error: ${response.body}");
        return null;
      }
    } catch (error) {
      print("Error placing order: $error");
      return null;
    }
  }
}
