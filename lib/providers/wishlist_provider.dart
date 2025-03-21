import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';

class WishlistProvider extends ChangeNotifier {
  final List<CartItem> _wishlist = [];

  List<CartItem> get wishlist => _wishlist;

  void addToWishlist(CartItem product) {
    if (!_wishlist.any((item) => item.id == product.id)) {
      _wishlist.add(product);
      print("Wishlist Updated: ${_wishlist.length} items");
      notifyListeners();
    } else {
      print("Item already in Wishlist");
    }
  }

  void removeFromWishlist(int productId) {
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  bool isWishlisted(int productId) {
    return _wishlist.any((item) => item.id == productId);
  }
}
