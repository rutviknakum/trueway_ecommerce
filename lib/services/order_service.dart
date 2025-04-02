import 'dart:convert';
import '../config/api_config.dart';
import '../models/cart_item.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  /// Fetches orders for the logged in user
  Future<List<Map<String, dynamic>>> fetchOrders({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      // Get current user info to check for customer ID
      final userInfo = await _apiService.getCurrentUser();
      if (!userInfo["logged_in"]) {
        throw Exception("User not logged in");
      }

      final customerId = userInfo["customer_id"];
      if (customerId == 0) {
        throw Exception("No customer ID found");
      }

      Map<String, dynamic> queryParams = {
        "customer": customerId.toString(),
        "page": page.toString(),
        "per_page": perPage.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams["status"] = status;
      }

      final response = await _apiService.authenticatedRequest(
        ApiConfig.ordersEndpoint,
        method: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> orders = json.decode(response.body);
        return orders.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load orders: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  /// Fetches a single order by ID
  Future<Map<String, dynamic>?> fetchOrderById(int orderId) async {
    try {
      final response = await _apiService.authenticatedRequest(
        "${ApiConfig.ordersEndpoint}/$orderId",
        method: 'GET',
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> order = json.decode(response.body);
        return order;
      } else {
        print("Failed to load order: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching order: $e");
      return null;
    }
  }

  /// Places a new order
  Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> cartItems,
    Map<String, String>? billingAddress,
    Map<String, String>? shippingAddress,
    String paymentMethod = "cod",
    String paymentMethodTitle = "Cash on Delivery",
  }) async {
    try {
      // Get current user info
      final userInfo = await _apiService.getCurrentUser();
      if (!userInfo["logged_in"]) {
        return {"success": false, "error": "User not logged in"};
      }

      // Map cart items to line_items format
      List<Map<String, dynamic>> lineItems =
          cartItems.map((item) {
            return {"product_id": item.id, "quantity": item.quantity};
          }).toList();

      // Process billing address
      final Map<String, dynamic> billing;
      if (billingAddress != null && billingAddress.isNotEmpty) {
        // Split name into first and last name
        List<String> nameParts = (billingAddress["name"] ?? "").split(' ');
        String firstName = nameParts.first;
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        billing = {
          "first_name": firstName,
          "last_name": lastName,
          "address_1": billingAddress["address"] ?? "",
          "city": billingAddress["city"] ?? "",
          "state": billingAddress["state"] ?? "",
          "postcode": billingAddress["zip"] ?? "",
          "country": billingAddress["country"] ?? "IN",
          "email": userInfo["email"] ?? billingAddress["email"] ?? "",
          "phone": billingAddress["phone"] ?? "",
        };
      } else {
        // Use minimal billing with email
        billing = {"email": userInfo["email"] ?? ""};
      }

      // Process shipping address
      final Map<String, dynamic> shipping;
      if (shippingAddress != null && shippingAddress.isNotEmpty) {
        List<String> nameParts = (shippingAddress["name"] ?? "").split(' ');
        String firstName = nameParts.first;
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        shipping = {
          "first_name": firstName,
          "last_name": lastName,
          "address_1": shippingAddress["address"] ?? "",
          "city": shippingAddress["city"] ?? "",
          "state": shippingAddress["state"] ?? "",
          "postcode": shippingAddress["zip"] ?? "",
          "country": shippingAddress["country"] ?? "IN",
          "phone": shippingAddress["phone"] ?? "",
        };
      } else if (billingAddress != null && billingAddress.isNotEmpty) {
        // Use billing address for shipping if no shipping address provided
        shipping = billing;
      } else {
        // Minimal shipping info
        shipping = {};
      }

      // Create order data
      Map<String, dynamic> orderData = {
        "customer_id": userInfo["customer_id"],
        "payment_method": paymentMethod,
        "payment_method_title": paymentMethodTitle,
        "set_paid": false,
        "billing": billing,
        "shipping": shipping,
        "line_items": lineItems,
      };

      final response = await _apiService.authenticatedRequest(
        ApiConfig.ordersEndpoint,
        method: 'POST',
        body: orderData,
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          "success": true,
          "order_id": responseData["id"],
          "order_number": responseData["number"],
          "data": responseData,
        };
      } else {
        print("Order API Error: ${response.statusCode} - ${response.body}");
        return {
          "success": false,
          "error": "Failed to place order",
          "status_code": response.statusCode,
        };
      }
    } catch (e) {
      print("Error placing order: $e");
      return {"success": false, "error": "Error placing order: $e"};
    }
  }

  /// Cancels an order
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await _apiService.authenticatedRequest(
        "${ApiConfig.ordersEndpoint}/$orderId",
        method: 'PUT',
        body: {"status": "cancelled"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {"success": true, "data": responseData};
      } else {
        return {
          "success": false,
          "error": "Failed to cancel order",
          "status_code": response.statusCode,
        };
      }
    } catch (e) {
      print("Error cancelling order: $e");
      return {"success": false, "error": "Error cancelling order: $e"};
    }
  }

  /// Gets available payment gateways
  Future<List<Map<String, dynamic>>> getPaymentGateways() async {
    try {
      final response = await _apiService.publicRequest(
        "/wc/v3/payment_gateways",
        method: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> gateways = json.decode(response.body);
        return gateways
            .where((gateway) => gateway["enabled"] == true)
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error getting payment gateways: $e");
      return [];
    }
  }
}
