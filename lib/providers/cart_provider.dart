import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _discountAmount = 0.0;

  List<CartItem> get items => _items;

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get discountAmount => _discountAmount;
  double get finalPrice => totalPrice - discountAmount;

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
  }

  void removeFromCart(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
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
    } else if (quantity == 0) {
      removeFromCart(id);
    }
  }

  void applyDiscount(String couponCode) {
    if (couponCode == "SAVE10") {
      _discountAmount = totalPrice * 0.10; // 10% discount
    } else {
      _discountAmount = 0.0;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discountAmount = 0.0;
    notifyListeners();
  }
}
