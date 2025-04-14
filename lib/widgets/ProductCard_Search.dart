import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/services/search_service.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';

class ProductCard_Search extends StatelessWidget {
  final dynamic product;
  final Function() onTap;
  final SearchService _searchService = SearchService();

  ProductCard_Search({Key? key, required this.product, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isOnSale = product['on_sale'] == true;
    String? regularPrice = product['regular_price']?.toString();
    String? salePrice = product['price']?.toString();
    bool hasDiscount =
        isOnSale &&
        regularPrice != null &&
        salePrice != null &&
        regularPrice != salePrice;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        color: context.adaptiveCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: _searchService.buildProductImage(product),
              ),
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product['name'] ?? "No Name",
                      style: context.titleTextStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Price section
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            "₹$regularPrice",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: context.adaptiveSubtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          "₹${product['price'] ?? '0'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: hasDiscount ? context.priceColor : null,
                          ),
                        ),
                      ],
                    ),

                    // Sale badge
                    if (isOnSale)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.discountBadgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SALE",
                          style: TextStyle(
                            color: context.primaryButtonTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
