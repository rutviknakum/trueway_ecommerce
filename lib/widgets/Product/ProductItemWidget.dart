import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';

class ProductItemWidget extends StatelessWidget {
  final dynamic product;
  final Function()? onTap;
  final bool showDiscount;
  final double cardElevation;
  final double imageHeight;
  final double borderRadius;

  const ProductItemWidget({
    Key? key,
    required this.product,
    this.onTap,
    this.showDiscount = true,
    this.cardElevation = 2.0,
    this.imageHeight = 120.0,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get image URL with proper fallback handling for different data structures
    String imageUrl = "";

    // Handle multiple possible image data structures
    if (product["images"] != null &&
        product["images"] is List &&
        product["images"].isNotEmpty &&
        product["images"][0] != null &&
        product["images"][0]["src"] != null) {
      // Structure: product["images"][0]["src"]
      imageUrl = product["images"][0]["src"];
    } else if (product["image"] != null &&
        product["image"].toString().isNotEmpty) {
      // Structure: product["image"]
      imageUrl = product["image"];
    }

    final String name = product["name"] ?? "Product";
    final double price =
        (product["price"] is num)
            ? product["price"].toDouble()
            : double.tryParse(product["price"]?.toString() ?? "0") ?? 0.0;

    // Fix null-safety issue by handling originalPrice differently
    double? originalPrice;
    if (product["originalPrice"] is num) {
      originalPrice = product["originalPrice"].toDouble();
    } else if (product["regular_price"] is num) {
      originalPrice = product["regular_price"].toDouble();
    } else {
      final String priceStr =
          product["regular_price"]?.toString() ??
          product["originalPrice"]?.toString() ??
          "";
      if (priceStr.isNotEmpty) {
        originalPrice = double.tryParse(priceStr);
      }
    }

    final bool hasDiscount =
        showDiscount && originalPrice != null && originalPrice > price;
    final int discountPercentage =
        hasDiscount ? ((1 - (price / originalPrice)) * 100).round() : 0;

    // Check if product is on sale based on different possible flags
    final bool isOnSale =
        (product["on_sale"] == true) ||
        (product["sale"] == true) ||
        hasDiscount;

    final bool inStock = product["inStock"] ?? true;

    // Get product ID for wishlist functionality
    final int productId = product["id"] is int ? product["id"] : 0;

    // Set fixed dimensions for our card to prevent overflow
    final double maxCardHeight = 210.0; // Reduced height to prevent overflow
    final double imageContainerHeight = 110.0; // Further reduced image height
    final double detailsHeight = 90.0; // Reduced details height

    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, _) {
        final bool isWishlisted =
            productId > 0 && wishlistProvider.isWishlisted(productId);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: maxCardHeight, // Fixed height container
            child: Card(
              margin: EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 0,
              ), // Reduced vertical margin
              elevation: cardElevation,
              clipBehavior: Clip.antiAlias, // Clip any overflowing content
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum required space
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image with discount badge if applicable
                  SizedBox(
                    height: imageContainerHeight,
                    child: Stack(
                      children: [
                        // Product image
                        Container(
                          height: imageContainerHeight,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    height: imageContainerHeight,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  )
                                  : Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                        ),

                        // Discount badge
                        if (hasDiscount)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                "-$discountPercentage%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // "On Sale" badge
                        if (isOnSale && !hasDiscount)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                "On Sale",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // Wishlist heart icon
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () {
                              if (productId > 0) {
                                if (isWishlisted) {
                                  wishlistProvider.removeFromWishlist(
                                    productId,
                                  );
                                } else {
                                  // Create a cart item to add to wishlist
                                  final cartItem = CartItem(
                                    id: productId,
                                    name: name,
                                    price: price,
                                    image: imageUrl,
                                    quantity: 1,
                                    imageUrl: imageUrl,
                                  );
                                  wishlistProvider.addToWishlist(cartItem);
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isWishlisted ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product details
                  Container(
                    height: detailsHeight,
                    padding: EdgeInsets.all(6.0), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name with fixed height
                        Container(
                          height: 32, // Reduced height
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Reduced font size
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: 2), // Reduced spacing
                        // Price and original price
                        Row(
                          children: [
                            // Current price
                            Text(
                              "₹${price.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15, // Reduced font size
                              ),
                            ),

                            if (hasDiscount) ...[
                              SizedBox(width: 6), // Reduced spacing
                              // Original price (strikethrough)
                              Text(
                                "₹${originalPrice!.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11, // Reduced font size
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 2), // Reduced spacing
                        // In stock label
                        Text(
                          inStock ? "In stock" : "Out of stock",
                          style: TextStyle(
                            color: inStock ? Colors.green : Colors.red,
                            fontSize: 10, // Reduced font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
