import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/screens/product_list_screen.dart';
import 'package:trueway_ecommerce/widgets/Product/ProductItemWidget.dart';

class ProductSectionWidget extends StatelessWidget {
  final String title;
  final List products;
  final bool isHorizontal;
  final Function(dynamic) onProductTap;
  final bool showViewAll;

  const ProductSectionWidget({
    Key? key,
    required this.title,
    required this.products,
    required this.isHorizontal,
    required this.onProductTap,
    this.showViewAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and View All row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: () {
                    // Navigate to a screen that shows all products in this category
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductListScreen(
                              title: title,
                              products: products,
                              onProductTap: onProductTap,
                            ),
                      ),
                    );
                  },
                  child: Text('View All'),
                ),
            ],
          ),
        ),

        // Product list
        isHorizontal
            ? SizedBox(
              height: 210, // Match exactly with ProductItemWidget maxCardHeight
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                padding: EdgeInsets.symmetric(horizontal: 16),
                // Prevent additional padding/margin that might cause overflow
                itemExtent: 160, // Fixed item width
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 10), // Reduced margin
                    child: SizedBox(
                      width: 150, // Slightly smaller to ensure no overflow
                      child: ProductItemWidget(
                        product: products[index],
                        onTap: () => onProductTap(products[index]),
                      ),
                    ),
                  );
                },
              ),
            )
            : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductItemWidget(
                  product: products[index],
                  onTap: () => onProductTap(products[index]),
                );
              },
            ),
      ],
    );
  }
}
