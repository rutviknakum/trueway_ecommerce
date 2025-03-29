import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/screens/CheckoutScreens/PreviewScreen.dart';

class ShippingScreen extends StatefulWidget {
  final Map<String, String> shippingAddress;

  ShippingScreen({required this.shippingAddress});

  @override
  _ShippingScreenState createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  // Shipping options
  String _selectedShippingMethod = 'standard';
  final Map<String, Map<String, dynamic>> _shippingOptions = {
    'standard': {
      'title': 'Standard Delivery',
      'cost': 0.0,
      'days': '3-5 days',
      'icon': Icons.local_shipping_outlined,
    },
    'express': {
      'title': 'Express Delivery',
      'cost': 100.0,
      'days': '1-2 days',
      'icon': Icons.local_shipping,
    },
  };

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckoutProgress(),
          Expanded(child: _buildShippingOptions()),
        ],
      ),
      bottomSheet: _buildBottomButtons(context),
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
                _buildStepConnector(isActive: true),
                _buildStepCircle("2", "SHIPPING", isActive: true),
                _buildStepConnector(isActive: false),
                _buildStepCircle("3", "PREVIEW", isActive: false),
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

  Widget _buildStepConnector({bool isActive = false}) {
    return Container(
      width: 30,
      height: 2,
      color: isActive ? Colors.orange : Colors.grey[300],
    );
  }

  Widget _buildShippingOptions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shipping Method",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Select your preferred shipping method",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Standard shipping option
          _buildShippingOption('standard'),
          SizedBox(height: 16),

          // Express shipping option
          _buildShippingOption('express'),

          SizedBox(height: 32),
          Text(
            "Shipping Address",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildAddressCard(),

          SizedBox(height: 32),
          Text(
            "Estimated Delivery",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildDeliveryEstimate(),
          SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildShippingOption(String id) {
    bool isSelected = _selectedShippingMethod == id;
    final option = _shippingOptions[id]!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.white,
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ]
                : [],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedShippingMethod = id;
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
              Icon(
                option['icon'] as IconData,
                color: isSelected ? Colors.orange : Colors.grey[600],
                size: 28,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.orange : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Delivery in ${option['days']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Text(
                option['cost'] > 0 ? "₹${option['cost'].toInt()}" : "FREE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: option['cost'] > 0 ? Colors.black87 : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.shippingAddress['name'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
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
    );
  }

  Widget _buildDeliveryEstimate() {
    final option = _shippingOptions[_selectedShippingMethod]!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.2),
            ),
            child: Icon(
              option['icon'] as IconData,
              color: Colors.orange,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option['title'] as String,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Your order will be delivered within ${option['days']}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
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
            // Pass shipping method to the next screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PreviewScreen(
                      shippingAddress: widget.shippingAddress,
                      shippingMethod: _selectedShippingMethod,
                      shippingCost:
                          _shippingOptions[_selectedShippingMethod]!['cost']
                              as double,
                    ),
              ),
            );
          },
          child: Text(
            "CONTINUE TO PREVIEW",
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
