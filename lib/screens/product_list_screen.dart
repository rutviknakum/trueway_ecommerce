import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/widgets/Product/ProductItemWidget.dart';

class ProductListScreen extends StatelessWidget {
  final String title;
  final List products;
  final Function(dynamic) onProductTap;

  const ProductListScreen({
    Key? key,
    required this.title,
    required this.products,
    required this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onProductTap(products[index]),
            // Replace with your actual product card implementation
            child: ProductItemWidget(product: products[index]),
          );
        },
      ),
    );
  }
}
