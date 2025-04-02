import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/Order_scrren/OrderConfirmationScreen.dart';
import 'package:trueway_ecommerce/services/order_service.dart';
import 'package:trueway_ecommerce/services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> shippingAddress;
  final String shippingMethod;
  final double shippingCost;
  final String orderNotes;

  PaymentScreen({
    required this.shippingAddress,
    required this.shippingMethod,
    required this.shippingCost,
    required this.orderNotes,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Payment options
  String _selectedPaymentMethod = 'cod';
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();
  final OrderService _orderService = OrderService();

  // Credit card form
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cod',
      'title': 'Cash on Delivery',
      'description': 'Pay when you receive the order',
      'icon': Icons.money,
    },
    {
      'id': 'card',
      'title': 'Credit/Debit Card',
      'description': 'Pay securely with your card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'upi',
      'title': 'UPI Payment',
      'description': 'Pay using any UPI app',
      'icon': Icons.account_balance_wallet,
    },
  ];

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
          Expanded(child: _buildPaymentOptions(cart)),
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
                _buildStepConnector(isActive: true, isCompleted: true),
                _buildStepCircle(
                  "3",
                  "PREVIEW",
                  isActive: false,
                  isCompleted: true,
                ),
                _buildStepConnector(isActive: true),
                _buildStepCircle("4", "PAYMENT", isActive: true),
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

  Widget _buildPaymentOptions(CartProvider cart) {
    double subtotal = cart.totalPrice;
    double discount = cart.discountAmount;
    double total = subtotal - discount + widget.shippingCost;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Select your preferred payment method",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Payment options
          ..._paymentMethods
              .map((method) => _buildPaymentMethod(method))
              .toList(),

          // Credit card form (shown only when card is selected)
          if (_selectedPaymentMethod == 'card') _buildCreditCardForm(),

          SizedBox(height: 32),

          // Order summary
          _buildOrderSummary(cart, total),
          SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == method['id'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.white,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                          ),
                        )
                        : null,
              ),
              SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.grey[100],
                ),
                child: Icon(
                  method['icon'] as IconData,
                  color: isSelected ? Colors.orange : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.orange : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      method['description'] as String,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
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
            "Card Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // Card number
          _buildTextField(
            controller: _cardNumberController,
            label: "Card Number",
            hint: "1234 5678 9012 3456",
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),

          // Card holder name
          _buildTextField(
            controller: _cardHolderController,
            label: "Card Holder Name",
            hint: "John Doe",
            prefixIcon: Icons.person,
          ),
          SizedBox(height: 16),

          // Expiry date and CVV
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expiryController,
                  label: "Expiry Date",
                  hint: "MM/YY",
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cvvController,
                  label: "CVV",
                  hint: "123",
                  prefixIcon: Icons.lock,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: TextStyle(fontSize: 14),
    );
  }

  Widget _buildOrderSummary(CartProvider cart, double total) {
    return Container(
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
            "Order Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Items", style: TextStyle(color: Colors.grey[700])),
              Text(
                "${cart.items.length}",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal", style: TextStyle(color: Colors.grey[700])),
              Text(
                "₹${cart.totalPrice.toStringAsFixed(0)}",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (cart.discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount", style: TextStyle(color: Colors.green)),
                Text(
                  "-₹${cart.discountAmount.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Shipping", style: TextStyle(color: Colors.grey[700])),
              Text(
                widget.shippingCost > 0
                    ? "₹${widget.shippingCost.toStringAsFixed(0)}"
                    : "FREE",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: widget.shippingCost > 0 ? null : Colors.green,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: Colors.grey[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹${total.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
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
          onPressed: _isProcessing ? null : () => _placeOrder(context, cart),
          child:
              _isProcessing
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "PROCESSING...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    "PLACE ORDER",
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

  void _placeOrder(BuildContext context, CartProvider cart) async {
    // Start processing
    setState(() {
      _isProcessing = true;
    });

    try {
      // IMPORTANT: Calculate the total amount before clearing the cart
      double subtotal = cart.totalPrice;
      double discount = cart.discountAmount;
      double totalAmount = subtotal - discount + widget.shippingCost;

      // Get current user info
      final userInfo = await _apiService.getCurrentUser();
      if (!userInfo["logged_in"]) {
        _showErrorDialog("Please log in to place an order");
        return;
      }

      // Place the order with the new OrderService
      final response = await _orderService.placeOrder(
        cartItems: cart.items,
        billingAddress: widget.shippingAddress, // Using shipping as billing
        shippingAddress: widget.shippingAddress,
        paymentMethod: _selectedPaymentMethod,
        paymentMethodTitle: _getPaymentMethodTitle(_selectedPaymentMethod),
      );

      if (response["success"]) {
        // Clear cart AFTER order is successful
        await cart.clearCart();

        // Navigate to confirmation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderConfirmationScreen(
                  orderId: response["order_id"] ?? 0,
                  finalPrice: totalAmount,
                ),
          ),
        );
      } else {
        _showErrorDialog(
          response["error"] ?? "Failed to place order. Please try again.",
        );
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    } finally {
      // Stop processing
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getPaymentMethodTitle(String method) {
    for (var paymentMethod in _paymentMethods) {
      if (paymentMethod['id'] == method) {
        return paymentMethod['title'];
      }
    }
    return "Cash on Delivery"; // Default
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Order Failed"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }
}
