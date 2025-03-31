import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/PaymentScreen.dart';

class PreviewScreen extends StatefulWidget {
  final Map<String, String> shippingAddress;
  final String shippingMethod;
  final double shippingCost;

  PreviewScreen({
    required this.shippingAddress,
    required this.shippingMethod,
    required this.shippingCost,
  });

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Map to store quantities for each product
  final Map<int, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Checkout",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black87),
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckoutProgress(),
          Expanded(child: _buildPreview(cart)),
        ],
      ),
      bottomSheet: _buildBottomButtons(context, cart),
    );
  }

  Widget _buildCheckoutProgress() {
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepCircle(
                  "1",
                  "ADDRESS",
                  isActive: false,
                  isCompleted: true,
                ),
                _buildStepConnector(isActive: true, isCompleted: true),
                _buildStepCircle(
                  "2",
                  "SHIPPING",
                  isActive: false,
                  isCompleted: true,
                ),
                _buildStepConnector(isActive: true),
                _buildStepCircle("3", "PREVIEW", isActive: true),
                _buildStepConnector(isActive: false),
                _buildStepCircle("4", "PAYMENT", isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(
    String number,
    String title, {
    bool isActive = false,
    bool isCompleted = false,
  }) {
    Color circleColor;
    Color textColor;
    IconData? icon;

    if (isCompleted) {
      circleColor = Colors.green;
      textColor = Colors.green;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = Colors.orange;
      textColor = Colors.orange;
      icon = null;
    } else {
      circleColor = Colors.grey[300]!;
      textColor = Colors.grey;
      icon = null;
    }

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: Center(
            child:
                icon != null
                    ? Icon(icon, color: Colors.white, size: 18)
                    : Text(
                      number,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({
    bool isActive = false,
    bool isCompleted = false,
  }) {
    Color color;
    if (isCompleted) {
      color = Colors.green;
    } else if (isActive) {
      color = Colors.orange;
    } else {
      color = Colors.grey[300]!;
    }

    return Container(width: 30, height: 2, color: color);
  }

  Widget _buildPreview(CartProvider cart) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShippingAddressSection(),
          _buildDivider(),
          _buildOrderDetailsSection(cart),
          _buildDivider(),
          _buildCouponSection(),
          _buildDivider(),
          _buildPricingSummary(cart),
          _buildDivider(),
          _buildNoteSection(),
          SizedBox(height: 100), // Space for bottom buttons
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], thickness: 6, height: 6);
  }

  Widget _buildShippingAddressSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shipping Address",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Go back to shipping
                  Navigator.pop(context); // Go back to address
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Change",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shippingAddress['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(widget.shippingAddress['address'] ?? ''),
                SizedBox(height: 4),
                Text(
                  '${widget.shippingAddress['city'] ?? ''}, ${widget.shippingAddress['state'] ?? ''} ${widget.shippingAddress['zip'] ?? ''}',
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      widget.shippingAddress['phone'] ?? '',
                      style: TextStyle(color: Colors.grey[700]),
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

  Widget _buildOrderDetailsSection(CartProvider cart) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          ...cart.items.map((item) => _buildOrderItem(item, cart)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(cartItem, CartProvider cart) {
    // Initialize quantity if not already set
    if (!_quantities.containsKey(cartItem.id)) {
      _quantities[cartItem.id] = cartItem.quantity;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child:
                cartItem.imageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        cartItem.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Center(child: Icon(Icons.image, color: Colors.grey)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  "₹${cartItem.price.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Quantity:",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Spacer(),
                    _buildQuantityControl(cartItem, cart),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(cartItem, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Decrease quantity button
          InkWell(
            onTap: () {
              if (_quantities[cartItem.id]! > 1) {
                setState(() {
                  _quantities[cartItem.id] = _quantities[cartItem.id]! - 1;
                });

                // Update cart
                cart.updateItemQuantity(cartItem.id, _quantities[cartItem.id]!);
              }
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.remove, size: 16, color: Colors.grey[700]),
            ),
          ),

          // Quantity display
          Container(
            width: 40,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Center(
              child: Text(
                "${_quantities[cartItem.id]}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Increase quantity button
          InkWell(
            onTap: () {
              setState(() {
                _quantities[cartItem.id] = _quantities[cartItem.id]! + 1;
              });

              // Update cart
              cart.updateItemQuantity(cartItem.id, _quantities[cartItem.id]!);
            },
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.add, size: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Coupon Code",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.discount_outlined, color: Colors.orange),
                ),
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: "Enter coupon code",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      // Apply coupon
                      final cart = Provider.of<CartProvider>(
                        context,
                        listen: false,
                      );
                      cart.applyDiscount(_couponController.text);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Coupon applied"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(
                      "APPLY",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(CartProvider cart) {
    double subtotal = cart.totalPrice;
    double discount = cart.discountAmount;
    double total = subtotal - discount + widget.shippingCost;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[50],
            ),
            child: Column(
              children: [
                _buildSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
                SizedBox(height: 12),
                if (discount > 0) ...[
                  _buildSummaryRow(
                    "Discount",
                    "-₹${discount.toStringAsFixed(0)}",
                    valueColor: Colors.green,
                  ),
                  SizedBox(height: 12),
                ],
                _buildSummaryRow(
                  "Shipping",
                  widget.shippingCost > 0
                      ? "₹${widget.shippingCost.toStringAsFixed(0)}"
                      : "FREE",
                  valueColor: widget.shippingCost > 0 ? null : Colors.green,
                ),
                SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(height: 16),
                _buildSummaryRow(
                  "Total",
                  "₹${total.toStringAsFixed(0)}",
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isTotal ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Notes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Add any special instructions for your order...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 80,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PaymentScreen(
                      shippingAddress: widget.shippingAddress,
                      shippingMethod: widget.shippingMethod,
                      shippingCost: widget.shippingCost,
                      orderNotes: _noteController.text,
                    ),
              ),
            );
          },
          child: Text(
            "CONTINUE TO PAYMENT",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
