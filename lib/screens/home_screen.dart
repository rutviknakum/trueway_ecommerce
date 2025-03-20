import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trueway_ecommerce/screens/Wishlist.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';
import 'SearchScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];
  List recentlyViewedProducts = [];
  List popularProducts = [];
  List categories = [];
  List wishlist = [];
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

      setState(() {
        products = fetchedProducts;
        categories = fetchedCategories;
        bannerUrl =
            fetchedBanners.isNotEmpty
                ? fetchedBanners[0]
                : "https://via.placeholder.com/300";
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching home data: $e");
    }
  }

  void addToRecentlyViewed(Map product) {
    setState(() {
      if (!recentlyViewedProducts.contains(product)) {
        recentlyViewedProducts.insert(0, product);
        if (recentlyViewedProducts.length > 10) {
          recentlyViewedProducts.removeLast();
        }
      }
    });
  }

  void toggleWishlist(Map product) {
    setState(() {
      if (wishlist.contains(product)) {
        wishlist.remove(product);
      } else {
        wishlist.add(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.favorite),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WishlistScreen(wishlist: wishlist),
                  ),
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
                    _buildProductGrid(products),
                    _buildSectionTitle("Recently Viewed"),
                    _buildProductGrid(recentlyViewedProducts),
                    _buildSectionTitle("Most Popular"),
                    _buildProductGrid(popularProducts),
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
                        imageUrl: category["image"],
                        width: 50,
                        height: 50,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                      SizedBox(height: 5),
                      Text(category["name"], style: TextStyle(fontSize: 12)),
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

  Widget _buildProductGrid(List productList) {
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
          final hasDiscount = product["regular_price"] != product["price"];
          final discountPercentage =
              hasDiscount
                  ? ((double.parse(product["regular_price"]) -
                          double.parse(product["price"])) /
                      double.parse(product["regular_price"]) *
                      100)
                  : 0;

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
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: product["images"][0]["src"],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product["name"],
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasDiscount)
                              Row(
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
                                  SizedBox(width: 5),
                                  Text(
                                    "-${discountPercentage.toStringAsFixed(0)}%",
                                    style: TextStyle(color: Colors.green),
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
                        wishlist.contains(product)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            wishlist.contains(product)
                                ? Colors.red
                                : Colors.grey,
                      ),
                      onPressed: () => toggleWishlist(product),
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
}
