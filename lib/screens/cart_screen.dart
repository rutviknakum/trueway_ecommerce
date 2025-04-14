// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/AddressScreen.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shopping Cart",
          style: Theme.of(context).appBarTheme.titleTextStyle,
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

                        // Get image URL from the item
                        String imageUrl =
                            item.image ?? "https://via.placeholder.com/150";

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
                                // Product image with improved handling
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface.withOpacity(0.9),
                                    child:
                                        imageUrl.isNotEmpty
                                            ? Image.network(
                                              imageUrl,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 30,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.4),
                                                  ),
                                                );
                                              },
                                            )
                                            : Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 30,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                              ),
                                            ),
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
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      // Display variation attributes if available
                                      if (item.attributes != null &&
                                          item.attributes!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Wrap(
                                            spacing: 5,
                                            children:
                                                item.attributes!.entries.map((
                                                  entry,
                                                ) {
                                                  return Chip(
                                                    label: Text(
                                                      "${entry.key}: ${entry.value}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.all(0),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          _buildQuantityButton(
                                            icon: Icons.remove,
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                // Normal quantity reduction
                                                cart.decrementItemQuantity(
                                                  item.id,
                                                  item.variationId,
                                                );
                                              } else {
                                                // Show confirmation dialog when quantity is 1
                                                _showRemoveConfirmationDialog(
                                                  context,
                                                  cart,
                                                  item.id,
                                                  item.name,
                                                  item.variationId,
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
                                              cart.incrementItemQuantity(
                                                item.id,
                                                item.variationId,
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
                                      item.variationId,
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
    String itemName, [
    int variationId = 0,
  ]) {
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
                  cart.removeFromCart(itemId, variationId); // Remove the item
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
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),

          // Show discount if applied
          if (cart.discountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discount:",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Text(
                    "-₹${cart.discountAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),

          // Show final price if discount is applied
          if (cart.discountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Final Price:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹${cart.finalPrice.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),
          // Proceed to Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ThemeConfig.getPrimaryButtonStyle(),
              onPressed:
                  cart.items.isEmpty
                      ? null // Disable button if cart is empty
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressScreen(),
                          ),
                        );
                      },
              child: Text(
                "Proceed to Checkout",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
