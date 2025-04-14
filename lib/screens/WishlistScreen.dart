import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/main_screen.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';
import 'package:trueway_ecommerce/widgets/common_widgets.dart';

class WishlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlist = wishlistProvider.wishlist; // Get wishlist items
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CommonWidgets.buildHeaderText(context, "My Wishlist"),
        elevation: 0,
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
                    color: context.adaptiveCardColor,
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
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).dividerTheme.color ??
                                        Colors.transparent,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      product.image != null &&
                                              product.image!.isNotEmpty
                                          ? Image.network(
                                            product.image ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Icon(
                                                  Icons.image_not_supported,
                                                  size: 30,
                                                  color:
                                                      context
                                                          .adaptiveSubtitleColor,
                                                ),
                                          )
                                          : Icon(
                                            Icons.image_not_supported,
                                            size: 30,
                                            color:
                                                context.adaptiveSubtitleColor,
                                          ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: context.titleTextStyle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    CommonWidgets.buildPriceText(
                                      context,
                                      product.price,
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
                                icon: Icon(
                                  Icons.delete,
                                  color: context.dangerColor,
                                ),
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
                                style: ThemeConfig.getAddToCartButtonStyle(),
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
    // final colorScheme = Theme.of(context).colorScheme;
    //  final textTheme = Theme.of(context).textTheme;

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
                  color: context.successColor.withOpacity(0.8),
                  size: 120,
                ),
                // Small heart bottom right
                Positioned(
                  bottom: 20,
                  right: 120,
                  child: Icon(
                    Icons.favorite,
                    color: context.successColor.withOpacity(0.4),
                    size: 40,
                  ),
                ),
                // Smaller heart bottom right
                Positioned(
                  bottom: 50,
                  right: 80,
                  child: Icon(
                    Icons.favorite,
                    color: context.successColor.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // No favorites text
          CommonWidgets.buildHeaderText(context, "No favorites yet."),
          SizedBox(height: 15),
          // Instruction text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: CommonWidgets.buildSubtitleText(
              context,
              "Tap any heart next to a product to favorite. We'll save them for you here!",
            ),
          ),
          SizedBox(height: 50),
          // Shop now button
          CommonWidgets.buildPrimaryButton(
            context: context,
            text: "SHOP NOW",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            },
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
                  style: TextStyle(
                    fontSize: 16,
                    color: context.adaptiveSubtitleColor,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).dividerTheme.color ?? Colors.grey[300]!,
                ),
                backgroundColor: context.secondarySurfaceColor,
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
