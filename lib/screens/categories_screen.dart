import 'package:flutter/material.dart';
import '../services/product_service.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  int selectedCategoryId = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await ProductService.fetchCategories();
      if (fetchedCategories.isNotEmpty) {
        setState(() {
          categories = fetchedCategories;
          selectedCategoryId = categories[0]['id'];
        });
        _loadProducts(categories[0]['id']);
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    try {
      final fetchedProducts = await ProductService.fetchProductsByCategory(
        categoryId,
      );
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Categories")),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category['name']),
                  selected: category['id'] == selectedCategoryId,
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category['id'];
                    });
                    _loadProducts(category['id']);
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child:
                products.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                      padding: EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                product['images'][0]['src'],
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "₹${product['price']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
