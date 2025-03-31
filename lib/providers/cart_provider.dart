import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _discountAmount = 0.0;
  String? _appliedCoupon;

  // Key for storing cart data in shared preferences
  final String _cartStorageKey = 'trueway_cart';
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
      final prefs = await SharedPreferences.getInstance();
      // Load cart items
      final cartData = prefs.getString(_cartStorageKey);
      if (cartData != null) {
        final List<dynamic> cartList = json.decode(cartData);
        _items =
            cartList.map((item) {
              return CartItem(
                id: item['id'],
                name: item['name'],
                price: item['price'].toDouble(),
                quantity: item['quantity'],
                imageUrl: item['imageUrl'],
                image: item['image'],
              );
            }).toList();
      }

      // Load coupon data
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
      final prefs = await SharedPreferences.getInstance();

      // Save cart items
      final List<Map<String, dynamic>> cartData =
          _items.map((item) {
            return {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'imageUrl': item.imageUrl,
              'image': item.image,
            };
          }).toList();

      await prefs.setString(_cartStorageKey, json.encode(cartData));

      // Save coupon data
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
    int index = _items.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      // If the item exists, increment its quantity by the quantity provided in 'item'
      _items[index] = CartItem(
        id: _items[index].id,
        name: _items[index].name,
        price: _items[index].price,
        quantity: _items[index].quantity + item.quantity,
        imageUrl: _items[index].imageUrl,
        image: _items[index].image,
      );
    } else {
      // If the item doesn't exist in the cart, add it with its provided quantity.
      _items.add(
        CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          imageUrl: item.imageUrl,
          image: item.image,
        ),
      );
    }
    notifyListeners();
    _saveCartToStorage();
  }

  void removeFromCart(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveCartToStorage();

    // If cart is empty, remove any applied coupon
    if (_items.isEmpty) {
      _discountAmount = 0.0;
      _appliedCoupon = null;
      _saveCartToStorage();
    }
  }

  void updateItemQuantity(int id, int quantity) {
    int index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && quantity > 0) {
      _items[index] = CartItem(
        id: _items[index].id,
        name: _items[index].name,
        price: _items[index].price,
        quantity: quantity,
        imageUrl: _items[index].imageUrl,
        image: _items[index].image,
      );
      notifyListeners();
      _saveCartToStorage();
    } else if (quantity == 0) {
      removeFromCart(id);
    }
  }

  void incrementItemQuantity(int id) {
    int index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      updateItemQuantity(id, _items[index].quantity + 1);
    }
  }

  void decrementItemQuantity(int id) {
    int index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && _items[index].quantity > 1) {
      updateItemQuantity(id, _items[index].quantity - 1);
    } else if (index >= 0 && _items[index].quantity == 1) {
      removeFromCart(id);
    }
  }

  void applyDiscount(String couponCode) {
    _appliedCoupon = couponCode;

    if (couponCode == "SAVE10") {
      _discountAmount = totalPrice * 0.10; // 10% discount
    } else if (couponCode == "SAVE20") {
      _discountAmount = totalPrice * 0.20; // 20% discount
    } else if (couponCode == "FLAT50") {
      _discountAmount = 50.0; // $50 off
    } else {
      _discountAmount = 0.0;
      _appliedCoupon = null;
    }

    notifyListeners();
    _saveCartToStorage();
  }

  void removeCoupon() {
    _discountAmount = 0.0;
    _appliedCoupon = null;
    notifyListeners();
    _saveCartToStorage();
  }

  void clearCart() {
    _items.clear();
    _discountAmount = 0.0;
    _appliedCoupon = null;
    notifyListeners();
    _saveCartToStorage();
  }

  CartItem? getItemById(int id) {
    int index = _items.indexWhere((item) => item.id == id);
    return index >= 0 ? _items[index] : null;
  }

  bool isInCart(int id) {
    return _items.any((item) => item.id == id);
  }
}
