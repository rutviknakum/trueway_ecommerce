import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import '../services/product_service.dart';

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
          categories = fetchedCategories;
          bannerUrl =
              fetchedBanners.isNotEmpty
                  ? fetchedBanners[0]
                  : "https://via.placeholder.com/300";
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

  void addToRecentlyViewed(Map product) {
    // Check if the widget is still mounted before updating state
    if (mounted) {
      setState(() {
        if (!recentlyViewedProducts.contains(product)) {
          recentlyViewedProducts.insert(0, product);
          if (recentlyViewedProducts.length > 10) {
            recentlyViewedProducts.removeLast();
          }
        }
      });
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

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
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                ),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBanner(),
                    _buildCategorySection(),
                    _buildSectionTitle("Newly Launched"),
                    _buildProductGrid(products, wishlistProvider),
                    if (recentlyViewedProducts.isNotEmpty) ...[
                      _buildSectionTitle("Recently Viewed"),
                      _buildProductGrid(
                        recentlyViewedProducts,
                        wishlistProvider,
                      ),
                    ],
                    if (popularProducts.isNotEmpty) ...[
                      _buildSectionTitle("Most Popular"),
                      _buildProductGrid(popularProducts, wishlistProvider),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: bannerUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder:
              (context, url) => Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              categories.map((category) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            category["image"] ??
                            "https://via.placeholder.com/50",
                        width: 50,
                        height: 50,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                      SizedBox(height: 5),
                      Text(
                        category["name"] ?? "",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductGrid(
    List productList,
    WishlistProvider wishlistProvider,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: productList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final product = productList[index];
          final bool isWishlisted = wishlistProvider.isWishlisted(
            product["id"],
          );
          final bool hasDiscount =
              product["regular_price"].toString() !=
              product["price"].toString();
          final discountPercentage =
              hasDiscount
                  ? ((double.parse(product["regular_price"].toString()) -
                          double.parse(product["price"].toString())) /
                      double.parse(product["regular_price"].toString()) *
                      100)
                  : 0;

          // Check if the product has images; if not, use a built-in fallback widget.
          final bool hasImages =
              product["images"] != null && product["images"].isNotEmpty;
          final String imageUrl =
              hasImages
                  ? product["images"][0]["src"]
                  : ""; // Empty string when no image available

          Widget productImageWidget;
          if (hasImages) {
            productImageWidget = CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            );
          } else {
            productImageWidget = Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey[700],
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              addToRecentlyViewed(product);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: productImageWidget),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product["name"] ?? "",
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                      decoration: TextDecoration.lineThrough,
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
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        final cartItem = CartItem(
                          id: product["id"],
                          name: product["name"],
                          image: hasImages ? imageUrl : "",
                          price: double.parse(product["price"].toString()),
                          imageUrl: '',
                        );

                        if (isWishlisted) {
                          wishlistProvider.removeFromWishlist(cartItem.id);
                          showSnackBar(
                            context,
                            "${product["name"]} removed from wishlist",
                          );
                        } else {
                          wishlistProvider.addToWishlist(cartItem);
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
                          borderRadius: BorderRadius.circular(5),
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
    );
  }

  @override
  void dispose() {
    // Clean up any resources here if needed
    super.dispose();
  }
}
