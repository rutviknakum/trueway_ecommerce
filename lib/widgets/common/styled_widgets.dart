import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/config/theme_extensions.dart';

// Add this to a new file: lib/widgets/common/styled_widgets.dart

// Price display with optional original price for showing discounts
class PriceTag extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double fontSize;

  const PriceTag({
    Key? key,
    required this.price,
    this.originalPrice,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          "₹${price.toStringAsFixed(1)}",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: context.priceColor,
          ),
        ),
        if (originalPrice != null) ...[
          SizedBox(width: 8),
          Text(
            "₹${originalPrice!.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: fontSize * 0.8,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}

// Discount badge shown on product cards
class DiscountBadge extends StatelessWidget {
  final int discountPercentage;

  const DiscountBadge({Key? key, required this.discountPercentage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.discountBadgeColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
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
    );
  }
}

// Stock status indicator (In Stock/Out of Stock)
class StockIndicator extends StatelessWidget {
  final bool inStock;

  const StockIndicator({Key? key, required this.inStock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inStock ? context.inStockColor : context.outOfStockColor,
          ),
        ),
        SizedBox(width: 4),
        Text(
          inStock ? "In stock" : "Out of stock",
          style: TextStyle(
            fontSize: 12,
            color: inStock ? context.inStockColor : context.outOfStockColor,
          ),
        ),
      ],
    );
  }
}

// Section header for product sections (Newly Launched, Most Popular, etc.)
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({Key? key, required this.title, this.onViewAll})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.sectionHeaderColor,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                "View All",
                style: TextStyle(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Styled button for Add to Cart
class AddToCartButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmall;

  const AddToCartButton({
    Key? key,
    required this.onPressed,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.shopping_cart_outlined),
        style: IconButton.styleFrom(
          backgroundColor: context.addToCartButtonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.shopping_cart_outlined),
      label: Text("Add to Cart"),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.addToCartButtonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// Styled button for Buy Now
class BuyNowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BuyNowButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text("Buy Now"),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.buyNowButtonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
