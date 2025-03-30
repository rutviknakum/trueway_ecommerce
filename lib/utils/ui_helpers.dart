import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';

class UIHelpers {
  /// Navigate to product details screen
  static void navigateToProductDetails(BuildContext context, dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  /// Add a product to the cart
  static void addToCart(
    BuildContext context,
    CartProvider cartProvider,
    dynamic product,
  ) {
    // Extract product data safely
    final productId = product["id"] ?? 0;
    final productName = product["name"] ?? 'No Name';
    final String priceStr = product["price"]?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Extract image URL safely
    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    // Create cart item
    final cartItem = CartItem(
      id: productId,
      name: productName,
      image: imageUrl,
      price: price,
      quantity: 1,
      imageUrl: imageUrl,
    );

    // Add to cart
    cartProvider.addToCart(cartItem);
    showSnackBar(context, "$productName added to cart");
  }

  /// Toggle product in wishlist
  static void toggleWishlist(
    BuildContext context,
    WishlistProvider wishlistProvider,
    dynamic product,
  ) {
    // Extract product data safely
    final productId = product["id"] ?? 0;
    final productName = product["name"] ?? 'No Name';
    final String priceStr = product["price"]?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Extract image URL safely
    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    // Create cart item
    final cartItem = CartItem(
      id: productId,
      name: productName,
      image: imageUrl,
      price: price,
      imageUrl: imageUrl,
    );

    // Check if already in wishlist
    final bool isWishlisted = wishlistProvider.isWishlisted(productId);

    if (isWishlisted) {
      wishlistProvider.removeFromWishlist(productId);
      showSnackBar(context, "$productName removed from wishlist");
    } else {
      wishlistProvider.addToWishlist(cartItem);
      showSnackBar(context, "$productName added to wishlist");
    }
  }

  /// Show a snackbar
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}
