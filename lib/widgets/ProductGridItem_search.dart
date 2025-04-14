import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/services/search_service.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';

class ProductGridItem_search extends StatelessWidget {
  final dynamic product;
  final Function() onTap;
  final SearchService _searchService = SearchService();

  ProductGridItem_search({Key? key, required this.product, required this.onTap})
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
        elevation: 3,
        color: context.adaptiveCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _searchService.buildProductImage(product),
                ),
              ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product['name'] ?? "No Name",
                    style: context.titleTextStyle.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price section
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Expanded(
                          child: Text(
                            "₹$regularPrice",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: context.adaptiveSubtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        "₹${product['price'] ?? '0'}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: hasDiscount ? context.priceColor : null,
                        ),
                      ),
                    ],
                  ),

                  // Sale badge
                  if (isOnSale)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.discountBadgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "SALE",
                        style: TextStyle(
                          color: context.primaryButtonTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
