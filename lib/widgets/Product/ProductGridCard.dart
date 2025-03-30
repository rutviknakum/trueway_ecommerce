import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trueway_ecommerce/utils/price_helper.dart';

class ProductGridCard extends StatelessWidget {
  final dynamic product;
  final bool isWishlisted;
  final VoidCallback onProductTap;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;

  const ProductGridCard({
    Key? key,
    required this.product,
    required this.isWishlisted,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onToggleWishlist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract product data
    final productName = product["name"] ?? "";

    // Get price info
    final priceInfo = PriceHelper.getPriceInfo(product);

    // Check if the product has images
    final bool hasImages =
        product["images"] != null && product["images"].isNotEmpty;
    final String imageUrl = hasImages ? product["images"][0]["src"] : "";

    return GestureDetector(
      onTap: onProductTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image and badges
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      child:
                          hasImages
                              ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.grey[400]!,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.error,
                                        size: 30,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 30,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                    ),
                  ),

                  // Discount badge
                  if (priceInfo.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "-${priceInfo.discountPercentage.round()}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleWishlist,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product details
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name
                    Text(
                      productName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),

                    // Price
                    Row(
                      children: [
                        Text(
                          "₹${priceInfo.price.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                priceInfo.hasDiscount
                                    ? Colors.red
                                    : Colors.black87,
                          ),
                        ),
                        if (priceInfo.hasDiscount) ...[
                          SizedBox(width: 6),
                          Text(
                            "₹${priceInfo.regularPrice.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 6),

                    // Add to cart button
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "ADD TO CART",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
