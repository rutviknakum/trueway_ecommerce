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

  @override
  void initState() {
    super.initState();
    fetchHomeData();
  }

  void fetchHomeData() async {
    try {
      final fetchedProducts = await ProductService.fetchProducts();
      final fetchedCategories = await ProductService.fetchCategories();
      final fetchedBanners = await ProductService.fetchBanners();

      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          products = fetchedProducts;
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                          UIHelpers.navigateToProductDetails(context, product);
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
                      showViewAll: false,
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
