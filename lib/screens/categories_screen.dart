import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/services/product_service.dart'; // Import ProductService

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List categories = [];
  List products = [];
  int selectedCategoryId = -1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndProducts();
  }

  // Fetch categories and products on screen load
  void fetchCategoriesAndProducts() async {
    try {
      final fetchedCategories = await ProductService.fetchCategories();
      if (fetchedCategories.isNotEmpty) {
        final fetchedProducts = await ProductService.fetchProductsByCategory(
          fetchedCategories[0]['id'],
        );
        setState(() {
          categories = fetchedCategories;
          products = fetchedProducts;
          selectedCategoryId = categories[0]['id'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("No categories found");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  // Update the products based on selected category
  void updateProductsForCategory(int categoryId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedProducts = await ProductService.fetchProductsByCategory(
        categoryId,
      );
      setState(() {
        products = fetchedProducts;
        selectedCategoryId = categoryId;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching products for category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    void showSnackBar(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  // Left side: Categories list
                  Container(
                    width: 120,
                    padding: EdgeInsets.all(10),
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () {
                            updateProductsForCategory(category['id']);
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  selectedCategoryId == category['id']
                                      ? Colors.orangeAccent
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category['name'] ?? 'Unknown Category',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Right side: Products grid
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (products.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No products found for this category.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final wishlistProvider =
                                    Provider.of<WishlistProvider>(
                                      context,
                                      listen: false,
                                    );
                                final bool isWishlisted = wishlistProvider
                                    .isWishlisted(product["id"]);
                                final price =
                                    double.tryParse(
                                      product['price'].toString(),
                                    ) ??
                                    0.0;
                                final regularPrice =
                                    double.tryParse(
                                      product['regular_price'].toString(),
                                    ) ??
                                    0.0;
                                final hasDiscount = regularPrice != price;
                                final discountPercentage =
                                    hasDiscount
                                        ? ((regularPrice - price) /
                                                regularPrice) *
                                            100
                                        : 0;

                                // Handle missing or empty images safely
                                final productImage =
                                    product['images'] != null &&
                                            product['images'].isNotEmpty
                                        ? product['images'][0]['src']
                                        : 'https://via.placeholder.com/150'; // Fallback image URL

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProductDetailsScreen(
                                              product: product,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 3,
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: CachedNetworkImage(
                                                imageUrl: productImage,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) =>
                                                        CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(Icons.error),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product["name"] ??
                                                        'No Name',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (hasDiscount)
                                                    Wrap(
                                                      spacing: 5,
                                                      children: [
                                                        Text(
                                                          "₹${product["price"]}",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          "₹${product["regular_price"]}",
                                                          style: TextStyle(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: IconButton(
                                            icon: Icon(
                                              isWishlisted
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  isWishlisted
                                                      ? Colors.red
                                                      : Colors.grey,
                                            ),
                                            onPressed: () {
                                              final cartItem = CartItem(
                                                id: product["id"],
                                                name: product["name"],
                                                image:
                                                    product["images"][0]["src"],
                                                price: price,
                                                imageUrl: '',
                                              );

                                              if (isWishlisted) {
                                                wishlistProvider
                                                    .removeFromWishlist(
                                                      cartItem.id,
                                                    );
                                                showSnackBar(
                                                  context,
                                                  "${product["name"]} removed from wishlist",
                                                );
                                              } else {
                                                wishlistProvider.addToWishlist(
                                                  cartItem,
                                                );
                                                showSnackBar(
                                                  context,
                                                  "${product["name"]} added to wishlist",
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        if (hasDiscount)
                                          Positioned(
                                            top: 5,
                                            left: 5,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                "-${discountPercentage.toStringAsFixed(0)}%",
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
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
