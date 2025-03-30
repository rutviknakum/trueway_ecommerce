import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/services/search_service.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final Function() onTap;
  final SearchService _searchService = SearchService();

  ProductCard({Key? key, required this.product, required this.onTap})
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
      child: Container(
        width: 280, // Fixed width to prevent horizontal constraints errors
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Set mainAxisSize to min
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

              // Product details - using Flexible to prevent overflow
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Use minimum required size
                    children: [
                      // Product name
                      Text(
                        product['name'] ?? "No Name",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price section - using Row with mainAxisSize.min
                      Row(
                        mainAxisSize: MainAxisSize.min, // This is important
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              "₹$regularPrice",
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
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
                              color: hasDiscount ? Colors.green : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      // Sale badge
                      if (isOnSale)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "SALE",
                            style: TextStyle(
                              color: Colors.white,
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
      ),
    );
  }
}
