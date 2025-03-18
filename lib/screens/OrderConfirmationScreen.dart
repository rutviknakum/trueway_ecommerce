import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:trueway_ecommerce/screens/home_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double finalPrice;

  OrderConfirmationScreen({required int orderId, required this.finalPrice})
    : orderId = orderId.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Confirmation"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BounceInDown(
              duration: Duration(milliseconds: 1000),
              child: Icon(Icons.check_circle, color: Colors.green, size: 100),
            ),
            SizedBox(height: 20),
            FadeIn(
              duration: Duration(milliseconds: 1200),
              child: Text(
                "Your Order is Confirmed!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            FadeIn(
              duration: Duration(milliseconds: 1400),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order ID:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "#$orderId",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹${finalPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            FadeIn(
              duration: Duration(milliseconds: 1600),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Continue Shopping",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 15),
            FadeIn(
              duration: Duration(milliseconds: 1800),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/order-history');
                },
                child: Text(
                  "View Order History",
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
