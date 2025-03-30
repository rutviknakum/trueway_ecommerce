import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';

class OrderService {
  final String baseUrl = "https://map.uminber.in/wp-json/wc/v3";
  final String consumerKey = "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  final String consumerSecret = "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  // Helper method for consistent authentication headers
  Map<String, String> _getAuthHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization":
          "Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}",
    };
  }

  Future<List<dynamic>> fetchOrders() async {
    try {
      final url = Uri.parse("$baseUrl/orders");

      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
          "Error fetching orders: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  Future<String?> getCustomerId(String email) async {
    try {
      final url = Uri.parse("$baseUrl/customers?email=$email");

      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> customers = jsonDecode(response.body);
        if (customers.isNotEmpty) {
          return customers[0]['id'].toString(); // Get first customer's ID
        }
      } else {
        print(
          "Error getting customer: ${response.statusCode} - ${response.body}",
        );
      }
      return null; // Customer not found
    } catch (e) {
      print("Error getting customer: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> placeOrder(
    String? customerId,
    List<CartItem> cartItems, {
    Map<String, String>? shippingAddress,
    String paymentMethod = "cod",
  }) async {
    try {
      final url = Uri.parse("$baseUrl/orders");

      // Map cart items to line_items format expected by WooCommerce
      List<Map<String, dynamic>> lineItems =
          cartItems.map((item) {
            return {
              "product_id": item.id,
              "quantity": item.quantity,
              // Price is typically handled by WooCommerce based on product ID
              // If you need to override it, you could add a price field
            };
          }).toList();

      // Use provided shipping address or fall back to defaults
      final Map<String, dynamic> shipping;
      if (shippingAddress != null && shippingAddress.isNotEmpty) {
        // Split name into first and last name
        List<String> nameParts = (shippingAddress["name"] ?? "John Doe").split(
          ' ',
        );
        String firstName = nameParts.first;
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        shipping = {
          "first_name": firstName,
          "last_name": lastName,
          "address_1": shippingAddress["address"] ?? "123 Street",
          "city": shippingAddress["city"] ?? "City",
          "state": shippingAddress["state"] ?? "",
          "postcode": shippingAddress["zip"] ?? "12345",
          "country": "IN",
          "phone": shippingAddress["phone"] ?? "1234567890",
        };
      } else {
        shipping = {
          "first_name": "John",
          "last_name": "Doe",
          "address_1": "123 Street",
          "city": "City",
          "state": "",
          "postcode": "12345",
          "country": "IN",
          "phone": "1234567890",
        };
      }

      // Create order data object
      Map<String, dynamic> orderData = {
        if (customerId != null && customerId.isNotEmpty)
          "customer_id": int.tryParse(customerId) ?? 0,
        "payment_method": paymentMethod,
        "payment_method_title": _getPaymentMethodTitle(paymentMethod),
        "set_paid": false,
        "billing": {
          ...shipping,
          "email": "customer@example.com", // Add customer email if available
        },
        "shipping": shipping,
        "line_items": lineItems,
      };

      print("Placing order with data: ${jsonEncode(orderData)}");

      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print("Order placed successfully! Order ID: ${responseData['id']}");
        return responseData;
      } else {
        print("Order API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      print("Error placing order: $error");
      return null;
    }
  }

  // Helper to get payment method title based on method code
  String _getPaymentMethodTitle(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI Payment';
      default:
        return 'Cash on Delivery';
    }
  }
}
