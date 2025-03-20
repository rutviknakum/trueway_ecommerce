import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService productService = ProductService();
  List products = [];
  List recentlyViewedProducts = [];
  List popularProducts = []; // Fetch from API if available
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  void fetchProducts() async {
    try {
      List<dynamic> fetchedProducts = await ProductService.fetchProducts();
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching products: $e");
    }
  }

  void addToRecentlyViewed(Map product) {
    setState(() {
      if (!recentlyViewedProducts.contains(product)) {
        recentlyViewedProducts.insert(0, product); // Add at the start
        if (recentlyViewedProducts.length > 10) {
          recentlyViewedProducts.removeLast(); // Limit to 10
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trueway Store"),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
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
        child: Image.network(
          "https://via.placeholder.com/400x150",
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    List<Map<String, String>> categories = [
      {"icon": "https://via.placeholder.com/50", "name": "Milk"},
      {"icon": "https://via.placeholder.com/50", "name": "Oil & Ghee"},
      {"icon": "https://via.placeholder.com/50", "name": "Pulses"},
      {"icon": "https://via.placeholder.com/50", "name": "Fruits"},
      {"icon": "https://via.placeholder.com/50", "name": "Vegetables"},
      {"icon": "https://via.placeholder.com/50", "name": "Milk"},
      {"icon": "https://via.placeholder.com/50", "name": "Oil & Ghee"},
      {"icon": "https://via.placeholder.com/50", "name": "Pulses"},
      {"icon": "https://via.placeholder.com/50", "name": "Fruits"},
      {"icon": "https://via.placeholder.com/50", "name": "Vegetables"},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ), // Spacing between icons
                  child: Column(
                    children: [
                      Image.network(
                        category["icon"]!,
                        width: 50,
                        height: 50,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(Icons.error),
                      ),
                      SizedBox(height: 5),
                      Text(category["name"]!, style: TextStyle(fontSize: 12)),
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: Text("View All")),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List products) {
    return Container(
      height: 250,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map? product) {
    if (product == null) return SizedBox();

    String imageUrl =
        (product["images"] != null && product["images"].isNotEmpty)
            ? product["images"][0]["src"]
            : "https://via.placeholder.com/150";

    return GestureDetector(
      onTap: () {
        addToRecentlyViewed(product);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductDetailsScreen(
                  product: product as Map<String, dynamic>,
                ),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: EdgeInsets.all(5),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
