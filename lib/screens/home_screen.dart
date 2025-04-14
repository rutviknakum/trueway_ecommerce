import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/categories_screen.dart';
import 'package:trueway_ecommerce/services/product_service.dart';
import 'package:trueway_ecommerce/widgets/home/banner_widget.dart';
import 'package:trueway_ecommerce/widgets/home/category_list_widget.dart';
import 'package:trueway_ecommerce/widgets/home/product_section_widget.dart';
import 'package:trueway_ecommerce/utils/ui_helpers.dart';
import 'package:trueway_ecommerce/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];
  List recentlyViewedProducts = [];
  List popularProducts = [];
  List categories = [];
  String bannerUrl = "";
  List<String> bannerUrls = [];
  bool isLoading = true;
  late ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();

    // Initialize with default values - multiple fallback banners
    bannerUrl = "https://picsum.photos/800/400?random=1";
    bannerUrls = [
      "https://picsum.photos/800/400?random=1",
      "https://picsum.photos/800/400?random=2",
      "https://picsum.photos/800/400?random=3",
    ];

    fetchHomeData();
  }

  // Changed return type from void to Future<void>
  Future<void> fetchHomeData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Start loading banners early
      final bannersPromise = _productService.fetchBanners();

      // Fetch products and categories
      final productsPromise = _productService.fetchProducts();
      final categoriesPromise = _productService.fetchCategories();

      // Wait for products and categories
      final fetchedProducts = await productsPromise;
      final fetchedCategories = await categoriesPromise;

      if (!mounted) return;

      // Update critical data first
      setState(() {
        products = fetchedProducts;

        // Getting popular products
        popularProducts = List.from(fetchedProducts)..shuffle();
        popularProducts = popularProducts.take(4).toList();

        categories = fetchedCategories;

        // Not loading anymore, even if banners are still coming
        isLoading = false;
      });

      // Then handle banners when they arrive
      try {
        final fetchedBanners = await bannersPromise;

        // Only update if we got valid URLs
        if (fetchedBanners.isNotEmpty && mounted) {
          print("Setting ${fetchedBanners.length} banner URLs");
          setState(() {
            bannerUrls = fetchedBanners;
            bannerUrl =
                fetchedBanners
                    .first; // Set the first one as the default single URL
          });
        }
      } catch (e) {
        print("Banner fetch error (keeping defaults): $e");
        // Keep using fallback URLs
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      print("Error fetching home data: $e");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load data. Pull down to refresh."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void addToRecentlyViewed(dynamic product) {
    if (!mounted) return;

    setState(() {
      // Remove if already present to avoid duplicates
      recentlyViewedProducts.removeWhere((p) => p["id"] == product["id"]);

      // Add at the beginning
      recentlyViewedProducts.insert(0, product);

      // Limit to 10 items
      if (recentlyViewedProducts.length > 10) {
        recentlyViewedProducts.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trueway Store",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartScreen()),
                    ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
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
      drawer: AppDrawer(),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh:
                    fetchHomeData, // Now correctly accepts a Future<void> function
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner section - passing both parameters,
                      // but bannerUrls is the one that will control the carousel
                      BannerWidget(
                        bannerUrl: bannerUrl,
                        bannerUrls: bannerUrls,
                      ),

                      // Categories section
                      // In HomeScreen.dart - where you use CategoryListWidget
                      CategoryListWidget(
                        categories: categories,
                        onCategoryTap: (category) {
                          // Navigate to your existing CategoryScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CategoriesScreen(category: category),
                            ),
                          );
                        },
                      ),

                      // Newly Launched section
                      ProductSectionWidget(
                        title: "Newly Launched",
                        products: products.take(10).toList(),
                        isHorizontal: true,
                        onProductTap: (product) {
                          addToRecentlyViewed(product);
                          UIHelpers.navigateToProductDetails(context, product);
                        },
                        showViewAll: true,
                      ),

                      // Recently Viewed section (if any)
                      if (recentlyViewedProducts.isNotEmpty)
                        ProductSectionWidget(
                          title: "Recently Viewed",
                          products: recentlyViewedProducts,
                          isHorizontal: true,
                          onProductTap: (product) {
                            UIHelpers.navigateToProductDetails(
                              context,
                              product,
                            );
                          },
                          showViewAll: true,
                        ),

                      // Banner always appears, regardless of recently viewed products
                      // Removed the conditional so it always appears
                      BannerWidget(
                        bannerUrl: bannerUrl,
                        bannerUrls: bannerUrls,
                      ),

                      // Most Popular section
                      ProductSectionWidget(
                        title: "Most Popular",
                        products: popularProducts,
                        isHorizontal: false,
                        onProductTap: (product) {
                          addToRecentlyViewed(product);
                          UIHelpers.navigateToProductDetails(context, product);
                        },
                        showViewAll: true,
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
