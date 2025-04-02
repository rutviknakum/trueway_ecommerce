import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/main_screen.dart';

class WishlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlist = wishlistProvider.wishlist; // Get wishlist items

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Wishlist",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        //  backgroundColor: Colors.white,
        //foregroundColor: Colors.black,
      ),
      body:
          wishlist.isEmpty
              ? _buildEmptyWishlist(context)
              : ListView.builder(
                itemCount: wishlist.length,
                itemBuilder: (context, index) {
                  final product = wishlist[index];

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.network(
                                product.image ??
                                    'https://via.placeholder.com/150',
                                width: 70,
                                height: 70,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                    ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "₹${product.price}",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// **Remove from Wishlist**
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  wishlistProvider.removeFromWishlist(
                                    product.id,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${product.name} removed from Wishlist",
                                      ),
                                    ),
                                  );
                                },
                              ),

                              /// **Add to Cart**
                              ElevatedButton.icon(
                                onPressed: () {
                                  // 1. Add to cart
                                  cartProvider.addToCart(product);

                                  // 2. Remove from wishlist
                                  wishlistProvider.removeFromWishlist(
                                    product.id,
                                  );

                                  // 3. Show notification
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${product.name} added to Cart and removed from Wishlist",
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.add_shopping_cart, size: 24),
                                label: Text("Add to Cart"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  /// Builds the empty wishlist UI as shown in the reference image
  Widget _buildEmptyWishlist(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Heart icon with animation
          Container(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main heart
                Icon(
                  Icons.favorite,
                  color: Color(0xFF8CD28C), // Light green color
                  size: 120,
                ),
                // Small heart bottom right
                Positioned(
                  bottom: 20,
                  right: 120,
                  child: Icon(
                    Icons.favorite,
                    color: Color(0xFFDCF9DC), // Very light green
                    size: 40,
                  ),
                ),
                // Smaller heart bottom right
                Positioned(
                  bottom: 50,
                  right: 80,
                  child: Icon(
                    Icons.favorite,
                    color: Color(0xFFDCF9DC), // Very light green
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // No favorites text
          Text(
            "No favorites yet.",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          // Instruction text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Tap any heart next to a product to favorite. We'll save them for you here!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 50),
          // Shop now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to shop/product listing page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                ); // Return to previous screen to simulate going to shop
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "SHOP NOW",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5B041), // Orange color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Search for items button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "SEARCH FOR ITEMS",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
