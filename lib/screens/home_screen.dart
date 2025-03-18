import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trueway_ecommerce/screens/categories_screen.dart';
import 'package:trueway_ecommerce/screens/profile_screen.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeContent(),
    CategoriesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ProductService productService = ProductService();
  List products = [];
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

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              _buildCategorySection(),
              _buildSectionTitle("Newly Launched"),
              _buildProductGrid(),
              _buildSectionTitle("Recently Viewed"),
              _buildProductGrid(),
              _buildSectionTitle("Most Popular"),
              _buildProductGrid(),
            ],
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
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            categories.map((category) {
              return Column(
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
              );
            }).toList(),
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

  Widget _buildProductGrid() {
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
