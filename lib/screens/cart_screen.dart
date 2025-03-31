import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/AddressScreen.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shopping Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          cart.items.isEmpty
              ? Center(
                child: Text(
                  "Your cart is empty!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              )
              : Column(
                children: [
                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];

                        // Fallback logic for the image: use imageUrl if available,
                        // otherwise use image, or a placeholder.
                        String imageUrl = "";
                        if (item.imageUrl.isNotEmpty) {
                          imageUrl = item.imageUrl;
                        } else if (item.image.isNotEmpty) {
                          imageUrl = item.image;
                        } else {
                          imageUrl = "https://via.placeholder.com/150";
                        }

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Product image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Product details: name, price, quantity controls
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "₹${item.price}",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _buildQuantityButton(
                                            icon: Icons.remove,
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                // Normal quantity reduction
                                                cart.updateItemQuantity(
                                                  item.id,
                                                  item.quantity - 1,
                                                );
                                              } else {
                                                // Show confirmation dialog when quantity is 1
                                                _showRemoveConfirmationDialog(
                                                  context,
                                                  cart,
                                                  item.id,
                                                  item.name,
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "${item.quantity}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          _buildQuantityButton(
                                            icon: Icons.add,
                                            onPressed: () {
                                              cart.updateItemQuantity(
                                                item.id,
                                                item.quantity + 1,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Remove button with confirmation dialog
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showRemoveConfirmationDialog(
                                      context,
                                      cart,
                                      item.id,
                                      item.name,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Cart summary + checkout section
                  _buildCartSummarySection(context, cart),
                ],
              ),
    );
  }

  /// Shows a confirmation dialog before removing an item from the cart
  void _showRemoveConfirmationDialog(
    BuildContext context,
    CartProvider cart,
    int itemId,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Remove Item"),
            content: Text("Do you want to remove $itemName from your cart?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close the dialog
                },
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  cart.removeFromCart(itemId); // Remove the item
                  Navigator.of(ctx).pop(); // Close the dialog

                  // Show a confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$itemName removed from cart"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text("Yes", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  /// Builds the summary section at the bottom with total price and a checkout button.
  Widget _buildCartSummarySection(BuildContext context, CartProvider cart) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Total price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹${cart.totalPrice.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Proceed to Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddressScreen()),
                );
              },
              child: Text(
                "Proceed to Checkout",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable widget for the quantity increment/decrement buttons.
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(icon: Icon(icon, size: 20), onPressed: onPressed),
    );
  }
}
