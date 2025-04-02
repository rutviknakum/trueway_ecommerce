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
  bool _isMounted = true; // Track if the widget is mounted
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
    fetchCategoriesAndProducts();
  }

  @override
  void dispose() {
    _isMounted = false; // Set mounted flag to false
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

  // Fetch categories and products on screen load
  void fetchCategoriesAndProducts() async {
    try {
      // Use the new product service methods
      final productService = ProductService();
      final fetchedCategories = await productService.fetchCategories();
      if (!_isMounted) return; // Check if still mounted

      if (fetchedCategories.isNotEmpty) {
        if (mounted) {
          // Check mounted property
          setState(() {
            categories = fetchedCategories;
            selectedCategoryId = fetchedCategories[0]['id'];
            selectedCategoryName = fetchedCategories[0]['name'];
          });
        }

        // Fetch products after categories are set
        await updateProductsForCategory(
          selectedCategoryId,
          selectedCategoryName,
        );
      } else {
        if (mounted) {
          // Check mounted property
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Check mounted property
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching data: $e");
    }
  }

  // Update the products based on selected category
  Future<void> updateProductsForCategory(
    int categoryId,
    String categoryName, {
    bool viewAll = false,
  }) async {
    if (!mounted) return; // Early return if widget is not mounted

    setState(() {
      isLoading = true;
      products = []; // Clear previous products
      _viewingAllProducts = viewAll;
      _currentPage = 1;
      _hasMoreProducts = true;
    });

    try {
      // Use the new product service methods
      final productService = ProductService();
      final fetchedProducts = await productService.fetchProducts(
        categoryId: categoryId,
        // If viewing all, specify pagination parameters
        page: viewAll ? _currentPage : 1,
        perPage: viewAll ? _perPage : _perPage,
      );

      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          products = fetchedProducts;
          selectedCategoryId = categoryId;
          selectedCategoryName = categoryName;
          isLoading = false;

          // If we're viewing all products, check if we might have more
          if (viewAll) {
            _hasMoreProducts = fetchedProducts.length == _perPage;
          }
        });
      }
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching products for category: $e");
    }
  }

  // Load more products when scrolling (for "View All" mode)
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
          _currentPage--; // Revert the page increment
        });
      }
      print("Error loading more products: $e");
    }
  }

  // Add product to cart with animation
  void _addToCart(BuildContext context, dynamic product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Extract product data
    final productId = product["id"] ?? 0;
    final productName = product["name"] ?? 'No Name';
    final String priceStr = product['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    // Extract image URL
    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    // Create cart item with the new model structure
    final cartItem = CartItem(
      id: productId,
      name: productName,
      image: imageUrl,
      price: price,
      quantity: 1,
      variationId: 0,
      imageUrl: null, // Default to 0 for simple products
    );

    // Add to cart
    cartProvider.addToCart(cartItem);

    // Play animation
    _animationController.reset();
    _animationController.forward();

    // Show confirmation
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
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          _viewingAllProducts ? selectedCategoryName : "Category",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: _viewingAllProducts ? 22 : 28,
          ),
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
            icon: Icon(Icons.search, color: Colors.grey[500], size: 28),
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
                        Icons.shopping_cart_outlined,
                        color: Colors.grey[500],
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
                      color: Colors.orange,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
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
        // Left side: Categories list
        SizedBox(
          width: 100,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategoryId == category['id'];

              return GestureDetector(
                onTap: () {
                  updateProductsForCategory(category['id'], category['name']);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? Colors.orange : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    category['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected ? Colors.orange : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              );
            },
          ),
        ),

        // Right side: Products
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                // Category Header with "View All" link
                Container(
                  color: Colors.grey[100],
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedCategoryName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Implement View All functionality
                          updateProductsForCategory(
                            selectedCategoryId,
                            selectedCategoryName,
                            viewAll: true,
                          );
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child:
                      products.isEmpty && !isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductListItem(
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
      color: Colors.grey[100],
      child: Column(
        children: [
          Expanded(
            child:
                products.isEmpty && !isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      itemCount:
                          _isLoadingMore
                              ? products.length + 1
                              : products.length,
                      itemBuilder: (context, index) {
                        if (index == products.length && _isLoadingMore) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                                strokeWidth: 2.0,
                              ),
                            ),
                          );
                        }
                        return _buildProductListItem(context, products[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, dynamic product) {
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    // Extract product data safely
    final productId = product["id"] ?? 0;
    final productName = product["name"] ?? 'No Name';
    wishlistProvider.isWishlisted(productId);

    // Handle prices safely
    final String priceStr = product['price']?.toString() ?? '0';
    final String regularPriceStr = product['regular_price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;
    final regularPrice = double.tryParse(regularPriceStr) ?? 0.0;

    final hasDiscount = regularPrice > 0 && regularPrice != price;
    final discountPercentage =
        hasDiscount ? ((regularPrice - price) / regularPrice) * 100 : 0;

    // Extract image URL safely
    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    // Check if product is in stock
    final bool inStock = product['in_stock'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Discount Label
              Stack(
                children: [
                  // Product Image
                  Hero(
                    tag: 'product_$productId',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          imageUrl.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                              ),
                    ),
                  ),

                  // Discount Label
                  if (hasDiscount)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
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

              SizedBox(width: 15),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Text(
                      productName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 10),

                    // Price Display - Wrapped in FittedBox to prevent overflow
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            "₹${price.toInt()}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (hasDiscount) ...[
                            SizedBox(width: 8),
                            Text(
                              "₹${regularPrice.toInt()}",
                              style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    // Stock Status
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: inStock ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          inStock ? "In stock" : "Out of stock",
                          style: TextStyle(
                            fontSize: 14,
                            color: inStock ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    // Add to Cart Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            inStock ? () => _addToCart(context, product) : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: inStock ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  inStock
                                      ? Colors.grey[300]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                            color: inStock ? Colors.black87 : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
