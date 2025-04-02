import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
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
  bool isLoading = true;
  late ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    fetchHomeData();
  }

  void fetchHomeData() async {
    try {
      // Use instance methods instead of static methods
      final fetchedProducts = await _productService.fetchProducts();
      final fetchedCategories = await _productService.fetchCategories();

      // For banners, we might need to adapt the method based on your new service structure
      List<String> fetchedBanners = [];
      try {
        // This might need adjustment depending on how banners are fetched in your new service
        fetchedBanners = await _getBanners();
      } catch (e) {
        print("Error fetching banners: $e");
        // Use a default banner if needed
        fetchedBanners = ["assets/images/placeholder_banner.jpg"];
      }

      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          products = fetchedProducts;

          // Getting popular products (in a real app, this would be based on user data)
          popularProducts = List.from(fetchedProducts)..shuffle();
          popularProducts = popularProducts.take(4).toList();

          categories = fetchedCategories;
          bannerUrl =
              fetchedBanners.isNotEmpty
                  ? fetchedBanners[0]
                  : "assets/images/placeholder_banner.jpg";
          isLoading = false;
        });
      }
    } catch (e) {
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() => isLoading = false);
        print("Error fetching home data: $e");
      }
    }
  }

  // Helper method to get banners (adapt this to your new service structure)
  Future<List<String>> _getBanners() async {
    // This is a temporary implementation - adapt it based on your actual service
    try {
      // Since we don't have direct access to banners in the new service structure,
      // we'll return a default banner for now.
      // You'll need to implement this properly based on your API structure

      // As a fallback, you could use the existing categories or products
      // that have images and extract those images

      if (products.isNotEmpty) {
        List<String> bannerUrls = [];
        for (var product in products.take(3)) {
          if (product['images'] != null &&
              product['images'] is List &&
              product['images'].isNotEmpty &&
              product['images'][0]['src'] != null) {
            bannerUrls.add(product['images'][0]['src']);
          }
        }

        if (bannerUrls.isNotEmpty) {
          return bannerUrls;
        }
      }

      // If we couldn't extract any images, return a default
      return ["assets/images/placeholder_banner.jpg"];
    } catch (e) {
      print("Error in _getBanners: $e");
      return ["assets/images/placeholder_banner.jpg"];
    }
  }

  void addToRecentlyViewed(dynamic product) {
    // Check if the widget is still mounted before updating state
    if (mounted) {
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
                      color: Colors.red,
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
      // Use the enhanced dynamic drawer
      drawer: AppDrawer(),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  // Implement pull-to-refresh
                  setState(() => isLoading = true);
                  fetchHomeData();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner section
                      BannerWidget(bannerUrl: bannerUrl),

                      // Categories section
                      CategoryListWidget(categories: categories),

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

                      // Most Popular section
                      ProductSectionWidget(
                        title: "Most Popular",
                        products: popularProducts,
                        isHorizontal: false,
                        onProductTap: (product) {
                          addToRecentlyViewed(product);
                          UIHelpers.navigateToProductDetails(context, product);
                        },
                        showViewAll: true, // Changed from false to true
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
