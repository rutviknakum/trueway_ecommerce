import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CartService {
  final ApiService _apiService = ApiService();
  static const String cartKey = "shopping_cart";

  /// Gets the current cart from local storage
  Future<List<CartItem>> getCart() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cartJson = prefs.getString(cartKey);

      if (cartJson == null || cartJson.isEmpty) {
        return [];
      }

      List<dynamic> cartData = json.decode(cartJson);
      return cartData.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      print("Error getting cart: $e");
      return [];
    }
  }

  /// Saves the cart to local storage
  Future<bool> saveCart(List<CartItem> cartItems) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> cartJson =
          cartItems.map((item) => item.toJson()).toList();
      await prefs.setString(cartKey, json.encode(cartJson));
      return true;
    } catch (e) {
      print("Error saving cart: $e");
      return false;
    }
  }

  /// Adds an item to the cart
  Future<bool> addToCart(CartItem item) async {
    try {
      List<CartItem> currentCart = await getCart();

      // Check if item already exists
      int existingIndex = currentCart.indexWhere(
        (cartItem) =>
            cartItem.id == item.id && cartItem.variationId == item.variationId,
      );

      if (existingIndex >= 0) {
        // Update quantity if item exists
        currentCart[existingIndex].quantity += item.quantity;
      } else {
        // Add new item
        currentCart.add(item);
      }

      return await saveCart(currentCart);
    } catch (e) {
      print("Error adding to cart: $e");
      return false;
    }
  }

  /// Updates cart item quantity
  Future<bool> updateCartItemQuantity(
    int productId,
    int variationId,
    int quantity,
  ) async {
    try {
      List<CartItem> currentCart = await getCart();

      int itemIndex = currentCart.indexWhere(
        (item) => item.id == productId && item.variationId == variationId,
      );

      if (itemIndex < 0) {
        return false; // Item not found
      }

      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        currentCart.removeAt(itemIndex);
      } else {
        // Update quantity
        currentCart[itemIndex].quantity = quantity;
      }

      return await saveCart(currentCart);
    } catch (e) {
      print("Error updating cart: $e");
      return false;
    }
  }

  /// Removes an item from the cart
  Future<bool> removeFromCart(int productId, int variationId) async {
    try {
      List<CartItem> currentCart = await getCart();

      currentCart.removeWhere(
        (item) => item.id == productId && item.variationId == variationId,
      );

      return await saveCart(currentCart);
    } catch (e) {
      print("Error removing from cart: $e");
      return false;
    }
  }

  /// Clears the entire cart
  Future<bool> clearCart() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(cartKey);
      return true;
    } catch (e) {
      print("Error clearing cart: $e");
      return false;
    }
  }

  /// Calculate cart totals
  Future<Map<String, dynamic>> getCartTotals() async {
    try {
      List<CartItem> cartItems = await getCart();

      if (cartItems.isEmpty) {
        return {"subtotal": 0.0, "total": 0.0, "item_count": 0, "items": []};
      }

      // We need to get the latest prices from the API
      double subtotal = 0.0;
      int itemCount = 0;
      List<Map<String, dynamic>> itemsWithPrices = [];

      for (var item in cartItems) {
        try {
          // Get current product data
          final response = await _apiService.publicRequest(
            "${ApiConfig.productsEndpoint}/${item.id}",
            method: 'GET',
          );

          if (response.statusCode == 200) {
            final productData = json.decode(response.body);

            // Get the correct price based on variation
            double price = 0.0;

            if (item.variationId > 0) {
              // Get variation price
              final variationResponse = await _apiService.publicRequest(
                "${ApiConfig.productsEndpoint}/${item.id}/variations/${item.variationId}",
                method: 'GET',
              );

              if (variationResponse.statusCode == 200) {
                final variationData = json.decode(variationResponse.body);
                price = double.tryParse(variationData['price'] ?? '0') ?? 0.0;
              } else {
                price = double.tryParse(productData['price'] ?? '0') ?? 0.0;
              }
            } else {
              // Use regular product price
              price = double.tryParse(productData['price'] ?? '0') ?? 0.0;
            }

            // Calculate line total
            double lineTotal = price * item.quantity;
            subtotal += lineTotal;
            itemCount += item.quantity;

            // Add item with updated price info
            itemsWithPrices.add({
              "id": item.id,
              "variation_id": item.variationId,
              "name": productData['name'] ?? "Product",
              "price": price,
              "regular_price":
                  double.tryParse(productData['regular_price'] ?? '0') ?? 0.0,
              "quantity": item.quantity,
              "line_total": lineTotal,
              "image":
                  productData['images']?.isNotEmpty == true
                      ? productData['images'][0]['src']
                      : null,
            });
          }
        } catch (e) {
          print("Error getting product data: $e");
        }
      }

      return {
        "subtotal": subtotal,
        "total": subtotal, // Add tax, shipping, etc. if needed
        "item_count": itemCount,
        "items": itemsWithPrices,
      };
    } catch (e) {
      print("Error calculating cart totals: $e");
      return {
        "subtotal": 0.0,
        "total": 0.0,
        "item_count": 0,
        "items": [],
        "error": e.toString(),
      };
    }
  }

  /// Apply coupon to the cart
  Future<Map<String, dynamic>> applyCoupon(String couponCode) async {
    try {
      // Validate the coupon code
      final response = await _apiService.publicRequest(
        "/wc/v3/coupons",
        method: 'GET',
        queryParams: {"code": couponCode},
      );

      if (response.statusCode == 200) {
        List<dynamic> coupons = json.decode(response.body);

        if (coupons.isEmpty) {
          return {"success": false, "error": "Invalid coupon code"};
        }

        Map<String, dynamic> coupon = coupons[0];

        // Check if coupon is valid
        if (coupon['date_expires'] != null) {
          DateTime expiryDate = DateTime.parse(coupon['date_expires']);
          if (expiryDate.isBefore(DateTime.now())) {
            return {"success": false, "error": "Coupon has expired"};
          }
        }

        // Store the applied coupon
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("applied_coupon", json.encode(coupon));

        return {
          "success": true,
          "coupon": coupon,
          "discount_type": coupon['discount_type'],
          "discount_amount": coupon['amount'],
        };
      } else {
        return {"success": false, "error": "Failed to validate coupon"};
      }
    } catch (e) {
      print("Error applying coupon: $e");
      return {"success": false, "error": "Error applying coupon: $e"};
    }
  }

  /// Remove applied coupon
  Future<bool> removeCoupon() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("applied_coupon");
      return true;
    } catch (e) {
      print("Error removing coupon: $e");
      return false;
    }
  }

  /// Get applied coupon
  Future<Map<String, dynamic>?> getAppliedCoupon() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? couponJson = prefs.getString("applied_coupon");

      if (couponJson == null || couponJson.isEmpty) {
        return null;
      }

      return json.decode(couponJson);
    } catch (e) {
      print("Error getting applied coupon: $e");
      return null;
    }
  }
}
