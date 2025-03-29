import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/services/product_service.dart';

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
        setState(() {
          categories = fetchedCategories;
          selectedCategoryId = fetchedCategories[0]['id'];
        });

        // Fetch products after categories are set
        await updateProductsForCategory(selectedCategoryId);
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
  Future<void> updateProductsForCategory(int categoryId) async {
    setState(() {
      isLoading = true;
      products = []; // Clear previous products
    });

    try {
      final fetchedProducts = await ProductService.fetchProductsByCategory(
        categoryId,
      );

      // Debug print to check product structure
      if (fetchedProducts.isNotEmpty) {
        print("Product sample: ${fetchedProducts[0]}");
      }

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

  // Safe method to extract image URL from product
  String getProductImageUrl(dynamic product) {
    try {
      if (product != null &&
          product['images'] != null &&
          product['images'] is List &&
          product['images'].isNotEmpty &&
          product['images'][0] != null &&
          product['images'][0]['src'] != null) {
        return product['images'][0]['src'];
      }
    } catch (e) {
      print("Error extracting image URL: $e");
    }
    return 'https://via.placeholder.com/150';
  }

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.grey[50],
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategoryId == category['id'];

                        return GestureDetector(
                          onTap: () {
                            updateProductsForCategory(category['id']);
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.orangeAccent
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 3,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Text(
                              category['name'] ?? 'Unknown Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Right side: Products grid
                  Expanded(
                    child:
                        products.isEmpty && !isLoading
                            ? Center(
                              child: Text(
                                'No products found for this category.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            : GridView.builder(
                              padding: EdgeInsets.all(10),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        1.04, // Calculated ideal aspect ratio
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final wishlistProvider =
                                    Provider.of<WishlistProvider>(
                                      context,
                                      listen: false,
                                    );

                                // Handle product data with null safety
                                final productId = product["id"] ?? 0;
                                final productName =
                                    product["name"] ?? 'No Name';
                                final bool isWishlisted = wishlistProvider
                                    .isWishlisted(productId);

                                // Handle prices safely
                                final String priceStr =
                                    product['price']?.toString() ?? '0';
                                final String regularPriceStr =
                                    product['regular_price']?.toString() ?? '0';
                                final price = double.tryParse(priceStr) ?? 0.0;
                                final regularPrice =
                                    double.tryParse(regularPriceStr) ?? 0.0;

                                final hasDiscount =
                                    regularPrice > 0 && regularPrice != price;
                                final discountPercentage =
                                    hasDiscount
                                        ? ((regularPrice - price) /
                                                regularPrice) *
                                            100
                                        : 0;

                                // Get product image safely
                                final productImage = getProductImageUrl(
                                  product,
                                );

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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                    margin: EdgeInsets.zero,
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Image container with fixed height
                                            Container(
                                              height:
                                                  110, // Further reduced height to prevent overflow
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                                child: CachedNetworkImage(
                                                  imageUrl: productImage,
                                                  fit: BoxFit.cover,
                                                  placeholder:
                                                      (
                                                        context,
                                                        url,
                                                      ) => Container(
                                                        color: Colors.grey[200],
                                                        child: Center(
                                                          child: SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 30,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),

                                            // Product details
                                            Padding(
                                              padding: EdgeInsets.all(
                                                6,
                                              ), // Reduced padding
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          12, // Smaller font size
                                                    ),
                                                    maxLines: 1, // Only 1 line
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(
                                                    height: 1,
                                                  ), // Minimal spacing
                                                  if (hasDiscount)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "₹$price",
                                                          style: TextStyle(
                                                            fontSize:
                                                                12, // Smaller font
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color.fromRGBO(
                                                              29,
                                                              27,
                                                              32,
                                                              1,
                                                            ), // Using your color code
                                                          ),
                                                        ),
                                                        SizedBox(width: 3),
                                                        Text(
                                                          "₹$regularPrice",
                                                          style: TextStyle(
                                                            fontSize:
                                                                10, // Smaller font
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  else
                                                    Text(
                                                      "₹$price",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromRGBO(
                                                          29,
                                                          27,
                                                          32,
                                                          1,
                                                        ), // Using your color code
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Wishlist button
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                isWishlisted
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    isWishlisted
                                                        ? Colors.red
                                                        : Colors.grey,
                                                size: 18, // Smaller icon
                                              ),
                                              onPressed: () {
                                                try {
                                                  final cartItem = CartItem(
                                                    id: productId,
                                                    name: productName,
                                                    image: productImage,
                                                    price: price,
                                                    imageUrl: productImage,
                                                  );

                                                  if (isWishlisted) {
                                                    wishlistProvider
                                                        .removeFromWishlist(
                                                          cartItem.id,
                                                        );
                                                    _showSnackBar(
                                                      context,
                                                      "$productName removed from wishlist",
                                                    );
                                                  } else {
                                                    wishlistProvider
                                                        .addToWishlist(
                                                          cartItem,
                                                        );
                                                    _showSnackBar(
                                                      context,
                                                      "$productName added to wishlist",
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    "Error handling wishlist: $e",
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),

                                        // Discount label
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
                  ),
                ],
              ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
