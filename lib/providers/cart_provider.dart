import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _discountAmount = 0.0;
  String? _appliedCoupon;
  final CartService _cartService = CartService();

  // Key for storing cart data in shared preferences
  final String _couponStorageKey = 'trueway_coupon';

  CartProvider() {
    _loadCartFromStorage();
  }

  List<CartItem> get items => [..._items]; // Return a copy of the items list

  int get itemCount => _items.length;

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get discountAmount => _discountAmount;
  double get finalPrice => totalPrice - discountAmount;
  String? get appliedCoupon => _appliedCoupon;

  // Load cart data from shared preferences
  Future<void> _loadCartFromStorage() async {
    try {
      _items = await _cartService.getCart();

      // Load coupon data
      final prefs = await SharedPreferences.getInstance();
      final couponData = prefs.getString(_couponStorageKey);
      if (couponData != null) {
        final Map<String, dynamic> couponMap = json.decode(couponData);
        _appliedCoupon = couponMap['code'];
        _discountAmount = couponMap['amount'].toDouble();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // Save cart data to shared preferences
  Future<void> _saveCartToStorage() async {
    try {
      await _cartService.saveCart(_items);

      // Save coupon data
      final prefs = await SharedPreferences.getInstance();
      if (_appliedCoupon != null) {
        final Map<String, dynamic> couponData = {
          'code': _appliedCoupon,
          'amount': _discountAmount,
        };
        await prefs.setString(_couponStorageKey, json.encode(couponData));
      } else {
        await prefs.remove(_couponStorageKey);
      }
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addToCart(CartItem item) {
    // Check if the item is already in the cart using its id.
    int index = _items.indexWhere(
      (element) =>
          element.id == item.id && element.variationId == item.variationId,
    );

    if (index >= 0) {
      // If the item exists, increment its quantity by the quantity provided in 'item'
      _items[index].quantity += item.quantity;
    } else {
      // If the item doesn't exist in the cart, add it with its provided quantity.
      _items.add(item);
    }
    notifyListeners();
    _saveCartToStorage();
  }

  void removeFromCart(int id, [int variationId = 0]) {
    _items.removeWhere(
      (item) => item.id == id && item.variationId == variationId,
    );

    notifyListeners();
    _saveCartToStorage();

    // If cart is empty, remove any applied coupon
    if (_items.isEmpty) {
      _discountAmount = 0.0;
      _appliedCoupon = null;
      _saveCartToStorage();
    }
  }

  void updateItemQuantity(int id, int quantity, [int variationId = 0]) {
    int index = _items.indexWhere(
      (item) => item.id == id && item.variationId == variationId,
    );

    if (index >= 0 && quantity > 0) {
      _items[index].quantity = quantity;
      notifyListeners();
      _saveCartToStorage();
    } else if (quantity == 0) {
      removeFromCart(id, variationId);
    }
  }

  void incrementItemQuantity(int id, [int variationId = 0]) {
    int index = _items.indexWhere(
      (item) => item.id == id && item.variationId == variationId,
    );

    if (index >= 0) {
      updateItemQuantity(id, _items[index].quantity + 1, variationId);
    }
  }

  void decrementItemQuantity(int id, [int variationId = 0]) {
    int index = _items.indexWhere(
      (item) => item.id == id && item.variationId == variationId,
    );

    if (index >= 0 && _items[index].quantity > 1) {
      updateItemQuantity(id, _items[index].quantity - 1, variationId);
    } else if (index >= 0 && _items[index].quantity == 1) {
      removeFromCart(id, variationId);
    }
  }

  Future<void> applyDiscount(String couponCode) async {
    final result = await _cartService.applyCoupon(couponCode);

    if (result['success']) {
      _appliedCoupon = couponCode;

      if (result['discount_type'] == 'percent') {
        // Percentage discount
        double percentValue = double.tryParse(result['discount_amount']) ?? 0;
        _discountAmount = totalPrice * (percentValue / 100);
      } else {
        // Fixed discount
        _discountAmount = double.tryParse(result['discount_amount']) ?? 0;
      }
    } else {
      // Fallback to simple coupon logic if API fails
      if (couponCode == "SAVE10") {
        _appliedCoupon = couponCode;
        _discountAmount = totalPrice * 0.10; // 10% discount
      } else if (couponCode == "SAVE20") {
        _appliedCoupon = couponCode;
        _discountAmount = totalPrice * 0.20; // 20% discount
      } else if (couponCode == "FLAT50") {
        _appliedCoupon = couponCode;
        _discountAmount = 50.0; // $50 off
      } else {
        _discountAmount = 0.0;
        _appliedCoupon = null;
      }
    }

    notifyListeners();
    _saveCartToStorage();
  }

  Future<void> removeCoupon() async {
    await _cartService.removeCoupon();
    _discountAmount = 0.0;
    _appliedCoupon = null;
    notifyListeners();
    _saveCartToStorage();
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
    _items.clear();
    _discountAmount = 0.0;
    _appliedCoupon = null;
    notifyListeners();
  }

  CartItem? getItemById(int id, [int variationId = 0]) {
    int index = _items.indexWhere(
      (item) => item.id == id && item.variationId == variationId,
    );
    return index >= 0 ? _items[index] : null;
  }

  bool isInCart(int id, [int variationId = 0]) {
    return _items.any(
      (item) => item.id == id && item.variationId == variationId,
    );
  }

  Future<void> refreshCartPrices() async {
    try {
      final cartTotals = await _cartService.getCartTotals();
      if (cartTotals['items'] != null) {
        List<dynamic> updatedItems = cartTotals['items'];

        // Update each item with the latest price
        for (var updatedItem in updatedItems) {
          int index = _items.indexWhere(
            (item) =>
                item.id == updatedItem['id'] &&
                item.variationId == updatedItem['variation_id'],
          );

          if (index >= 0) {
            _items[index].price = updatedItem['price'];
          }
        }

        // Recalculate discount if percentage-based
        if (_appliedCoupon != null) {
          // For demo purposes, simple logic - in real app get from API
          if (_appliedCoupon == "SAVE10") {
            _discountAmount = totalPrice * 0.10;
          } else if (_appliedCoupon == "SAVE20") {
            _discountAmount = totalPrice * 0.20;
          }
        }

        notifyListeners();
        _saveCartToStorage();
      }
    } catch (e) {
      debugPrint('Error refreshing cart prices: $e');
    }
  }
}
