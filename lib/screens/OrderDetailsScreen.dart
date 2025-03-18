import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order['id']}"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Order Summary"),
            _buildOrderDetails(),
            SizedBox(height: 20),
            _buildSectionTitle("Items"),
            _buildOrderItems(),
            SizedBox(height: 20),
            _buildSectionTitle("Billing Details"),
            _buildBillingDetails(),
            Spacer(),
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Order ID:", "#${order['id']}"),
            _buildDetailRow("Total Amount:", "₹${order['total']}"),
            _buildDetailRow(
              "Status:",
              order['status'] != null
                  ? order['status'].toUpperCase()
                  : "UNKNOWN",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Column(
      children:
          order['line_items'] != null
              ? List.generate(order['line_items'].length, (index) {
                var item = order['line_items'][index];
                return ListTile(
                  title: Text(
                    item['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Quantity: ${item['quantity']}"),
                  trailing: Text("₹${item['total']}"),
                );
              })
              : [
                Text("No items in this order", style: TextStyle(fontSize: 16)),
              ],
    );
  }

  Widget _buildBillingDetails() {
    var billing = order['billing'] ?? {};
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              "Name:",
              "${billing['first_name'] ?? 'N/A'} ${billing['last_name'] ?? 'N/A'}",
            ),
            _buildDetailRow("Email:", billing['email'] ?? 'N/A'),
            _buildDetailRow("Phone:", billing['phone'] ?? 'N/A'),
            _buildDetailRow(
              "Address:",
              "${billing['address_1'] ?? 'N/A'}, ${billing['city'] ?? 'N/A'}, ${billing['state'] ?? 'N/A'}, ${billing['postcode'] ?? 'N/A'}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "Back to Orders",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
