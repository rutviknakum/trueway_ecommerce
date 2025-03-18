import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/screens/OrderConfirmationScreen.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatelessWidget {
  final TextEditingController _couponController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("It's ordered!", "Order No "),
          _buildOrderDetails(cart, context),
          _buildCouponInput(cart),
          _buildPricingSummary(cart),
          _buildSuccessMessage(),
          _buildBottomButtons(context, cart),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(CartProvider cart, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORDER DETAILS", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ...cart.items
              .map((item) => _buildOrderItem(item, cart, context))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(cartItem, CartProvider cart, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cartItem.imageUrl != null && cartItem.imageUrl.isNotEmpty
              ? Image.network(cartItem.imageUrl, width: 60, height: 60)
              : SizedBox(width: 60, height: 60),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${cartItem.price}",
                  style: TextStyle(color: Colors.green),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed:
                          () => cart.updateItemQuantity(
                            cartItem.id,
                            cartItem.quantity - 1,
                          ),
                    ),
                    Text("x${cartItem.quantity}"),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed:
                          () => cart.updateItemQuantity(
                            cartItem.id,
                            cartItem.quantity + 1,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInput(CartProvider cart) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _couponController,
              decoration: InputDecoration(
                labelText: "Enter Coupon Code",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              cart.applyDiscount(_couponController.text);
            },
            child: Text("Apply"),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(CartProvider cart) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          _buildPriceRow("Subtotal", "₹${cart.totalPrice}"),
          _buildPriceRow("Discount", "₹${cart.discountAmount}"),
          _buildPriceRow("Total tax", "₹0"),
          _buildPriceRow("Shipping", "₹0"),
          Divider(),
          _buildPriceRow("Total", "₹${cart.finalPrice}", isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        "You've successfully placed the order! Check your email for confirmation.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, CartProvider cart) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to Shopping"),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final orderService = OrderService();
                final customerId = await orderService.getCustomerId(
                  "user@example.com",
                );
                final response = await orderService.placeOrder(
                  customerId,
                  cart.items,
                );
                if (response != null) {
                  print(
                    "Order placed successfully! Order ID: ${response['id']}",
                  );
                  cart.clearCart();
                  print("Total Price Before Navigation: ₹${cart.totalPrice}");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OrderConfirmationScreen(
                            orderId: response['id'],
                            finalPrice: cart.finalPrice,
                          ),
                    ),
                  );
                } else {
                  print("Order failed!");
                }
              },
              child: Text("Place Order"),
            ),
          ),
        ],
      ),
    );
  }
}
