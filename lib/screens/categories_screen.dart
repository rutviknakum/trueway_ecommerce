import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/services/product_service.dart';

class CategoriesScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoriesScreen({Key? key, this.category}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  List categories = [];
  List products = [];
  int selectedCategoryId = -1;
  String selectedCategoryName = "";
  bool isLoading = true;
  bool isLoadingProducts = false;
  bool _isMounted = true;
  late AnimationController _animationController;
  bool _viewingAllProducts = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  final int _perPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);

    if (widget.category != null) {
      int categoryId;
      if (widget.category!['id'] is int) {
        categoryId = widget.category!['id'];
      } else if (widget.category!['id'] is String) {
        categoryId = int.tryParse(widget.category!['id'].toString()) ?? -1;
      } else {
        categoryId = -1;
      }

      final categoryName = widget.category!['name']?.toString() ?? "";
      _viewingAllProducts = true;
      fetchCategoriesAndInitialProducts(categoryId, categoryName);
    } else {
      fetchCategoriesAndProducts();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_viewingAllProducts && _hasMoreProducts && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  void fetchCategoriesAndInitialProducts(
    int categoryId,
    String categoryName,
  ) async {
    try {
      final productService = ProductService();
      final fetchedCategories = await productService.fetchCategories();

      if (!_isMounted) return;

      if (fetchedCategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            categories = fetchedCategories;
            selectedCategoryId = categoryId;
            selectedCategoryName = categoryName;
          });
        }

        await updateProductsForCategory(
          categoryId,
          categoryName,
          viewAll: true,
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching data: $e");
    }
  }

  void fetchCategoriesAndProducts() async {
    try {
      final productService = ProductService();
      final fetchedCategories = await productService.fetchCategories();

      if (!_isMounted) return;

      if (fetchedCategories.isNotEmpty) {
        int firstCategoryId;
        if (fetchedCategories[0]['id'] is int) {
          firstCategoryId = fetchedCategories[0]['id'];
        } else if (fetchedCategories[0]['id'] is String) {
          firstCategoryId =
              int.tryParse(fetchedCategories[0]['id'].toString()) ?? -1;
        } else {
          firstCategoryId = -1;
        }

        String firstCategoryName =
            fetchedCategories[0]['name']?.toString() ?? "";

        if (mounted) {
          setState(() {
            categories = fetchedCategories;
            selectedCategoryId = firstCategoryId;
            selectedCategoryName = firstCategoryName;
          });
        }

        await updateProductsForCategory(
          selectedCategoryId,
          selectedCategoryName,
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching data: $e");
    }
  }

  Future<void> updateProductsForCategory(
    int categoryId,
    String categoryName, {
    bool viewAll = false,
  }) async {
    if (!mounted) return;

    setState(() {
      isLoadingProducts = true;
      products = [];
      _viewingAllProducts = viewAll;
      _currentPage = 1;
      _hasMoreProducts = true;
    });

    try {
      final productService = ProductService();
      final fetchedProducts = await productService.fetchProducts(
        categoryId: categoryId,
        page: viewAll ? _currentPage : 1,
        perPage: viewAll ? _perPage : _perPage,
      );

      if (mounted) {
        setState(() {
          products = fetchedProducts;
          selectedCategoryId = categoryId;
          selectedCategoryName = categoryName;
          isLoadingProducts = false;
          isLoading = false;

          if (viewAll) {
            _hasMoreProducts = fetchedProducts.length == _perPage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
          isLoading = false;
        });
      }
      print("Error fetching products for category: $e");
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || _isLoadingMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final productService = ProductService();
      final moreProducts = await productService.fetchProducts(
        categoryId: selectedCategoryId,
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          if (moreProducts.isNotEmpty) {
            products.addAll(moreProducts);
          }
          _isLoadingMore = false;
          _hasMoreProducts = moreProducts.length == _perPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
      print("Error loading more products: $e");
    }
  }

  void _addToCart(BuildContext context, dynamic product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    int productId;
    if (product["id"] is int) {
      productId = product["id"];
    } else if (product["id"] is String) {
      productId = int.tryParse(product["id"].toString()) ?? 0;
    } else {
      productId = 0;
    }

    final productName = product["name"]?.toString() ?? 'No Name';
    final String priceStr = product['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    final cartItem = CartItem(
      id: productId,
      name: productName,
      image: imageUrl,
      price: price,
      quantity: 1,
      variationId: 0,
      imageUrl: null,
    );

    cartProvider.addToCart(cartItem);
    _animationController.reset();
    _animationController.forward();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "$productName added to cart",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => CartScreen()));
              },
              child: Text(
                "VIEW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.items.length;

    return Scaffold(
      appBar: AppBar(
        elevation: Theme.of(context).appBarTheme.elevation,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          _viewingAllProducts ? selectedCategoryName : "Category",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        leading:
            _viewingAllProducts
                ? IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _viewingAllProducts = false;
                    });
                    updateProductsForCategory(
                      selectedCategoryId,
                      selectedCategoryName,
                    );
                  },
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _animationController.value * 0.3,
                      child: Icon(
                        Icons.shopping_cart,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        size: 28,
                      ),
                    );
                  },
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : _viewingAllProducts
              ? _buildAllProductsView()
              : _buildCategoriesView(),
    );
  }

  Widget _buildCategoriesView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Categories list with classic styling
        Container(
          width: 100,
          color: Colors.grey[50],
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              int categoryId;
              if (category['id'] is int) {
                categoryId = category['id'];
              } else if (category['id'] is String) {
                categoryId = int.tryParse(category['id'].toString()) ?? -1;
              } else {
                categoryId = -1;
              }

              final isSelected = selectedCategoryId == categoryId;

              String imageUrl = '';
              if (category['image'] != null) {
                if (category['image'] is Map &&
                    category['image']['src'] != null) {
                  imageUrl = category['image']['src'].toString();
                } else if (category['image'] is String) {
                  imageUrl = category['image'];
                }
              }

              return GestureDetector(
                onTap: () {
                  String categoryName = '';
                  if (category['name'] != null) {
                    categoryName = category['name'].toString();
                  }

                  updateProductsForCategory(categoryId, categoryName);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(
                        color:
                            isSelected ? Colors.teal[600]! : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Category Image with classic frame
                      Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.category,
                                        size: 24,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.category,
                                  size: 24,
                                  color: Colors.grey[400],
                                ),
                      ),
                      SizedBox(height: 8),
                      // Category Name with classic typography
                      Text(
                        category['name']?.toString() ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? Colors.teal[700] : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Right side: Products Grid with classic styling
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Category Header with classic styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedCategoryName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          updateProductsForCategory(
                            selectedCategoryId,
                            selectedCategoryName,
                            viewAll: true,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Products Grid View with classic styling
                Expanded(
                  child:
                      isLoadingProducts
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.teal[600]!,
                              ),
                            ),
                          )
                          : products.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try selecting a different category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : GridView.builder(
                            padding: EdgeInsets.all(10),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  // Adjusted aspect ratio to remove extra space
                                  childAspectRatio: 0.56,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildClassicProductItem(
                                context,
                                products[index],
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllProductsView() {
    return Container(
      color: Colors.white,
      child:
          isLoadingProducts
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[600]!),
                ),
              )
              : products.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // Adjusted aspect ratio to remove extra space
                  childAspectRatio: 0.56,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount:
                    _isLoadingMore ? products.length + 1 : products.length,
                itemBuilder: (context, index) {
                  if (index == products.length && _isLoadingMore) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.teal[600]!,
                          ),
                          strokeWidth: 2.0,
                        ),
                      ),
                    );
                  }
                  return _buildClassicProductItem(context, products[index]);
                },
              ),
    );
  }

  Widget _buildClassicProductItem(BuildContext context, dynamic product) {
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    int productId;
    if (product["id"] is int) {
      productId = product["id"];
    } else if (product["id"] is String) {
      productId = int.tryParse(product["id"].toString()) ?? 0;
    } else {
      productId = 0;
    }

    final productName = product["name"]?.toString() ?? 'No Name';
    wishlistProvider.isWishlisted(productId);

    final String priceStr = product['price']?.toString() ?? '0';
    final String regularPriceStr = product['regular_price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;
    final regularPrice = double.tryParse(regularPriceStr) ?? 0.0;

    final hasDiscount = regularPrice > 0 && regularPrice != price;
    final discountPercentage =
        hasDiscount ? ((regularPrice - price) / regularPrice) * 100 : 0;

    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'].toString();
    }

    final bool inStock = product['in_stock'] ?? true;

    // Classic product card with border and subtle shadows
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with classic frame styling
            Stack(
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: Hero(
                    tag: 'product_$productId',
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 24,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                            : Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 24,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                ),

                // Classic ribbon-style discount label
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        "-${discountPercentage.toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details section - REDUCED BOTTOM PADDING
            Padding(
              // Reduced bottom padding to remove extra space
              padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Very minimal space - similar to screenshot
                  SizedBox(height: 2),

                  // Price Display
                  Row(
                    children: [
                      Text(
                        "₹${price.toInt()}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      if (hasDiscount) ...[
                        SizedBox(width: 4),
                        Text(
                          "₹${regularPrice.toInt()}",
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Reduced spacing between price and bottom controls
                  SizedBox(height: 4),

                  // Stock status and Add to Cart row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green[50] : Colors.red[50],
                          border: Border.all(
                            color:
                                inStock ? Colors.green[300]! : Colors.red[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          inStock ? "In stock" : "Out of stock",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color:
                                inStock ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),

                      // Add to Cart Button
                      GestureDetector(
                        onTap:
                            inStock ? () => _addToCart(context, product) : null,
                        child: Container(
                          // Adjusted padding to match screenshot
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                inStock ? Colors.teal[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                            boxShadow:
                                inStock
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 1,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                "Add",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
