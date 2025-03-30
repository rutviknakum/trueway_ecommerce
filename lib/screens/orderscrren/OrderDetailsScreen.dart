import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final dynamic order;

  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    List<dynamic> lineItems = order['line_items'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Order #${order['id']}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            SizedBox(height: 16),
            _buildOrderItems(lineItems),
            SizedBox(height: 16),
            _buildAddressCard(),
            SizedBox(height: 16),
            _buildTotalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String status = order['status'] ?? 'pending';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'on-hold':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'refunded':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    String dateCreated = order['date_created'] ?? 'N/A';
    String formattedDate = _formatDate(dateCreated);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  "Order Date: $formattedDate",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Text(
                  "Payment Method: ${order['payment_method_title'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(List<dynamic> lineItems) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Items",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            lineItems.isEmpty
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No items found in this order."),
                  ),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: lineItems.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final item = lineItems[index];
                    final hasImage =
                        item['image'] != null && item['image']['src'] != null;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              hasImage
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['image']['src'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[400],
                                          ),
                                    ),
                                  )
                                  : Icon(Icons.image, color: Colors.grey[400]),
                        ),
                        SizedBox(width: 12),

                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'Product',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Quantity: ${item['quantity'] ?? 1}",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "₹${item['price'] ?? '0.00'}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final billing = order['billing'] ?? {};
    final shipping = order['shipping'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Delivery Address",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              "${shipping['first_name'] ?? ''} ${shipping['last_name'] ?? ''}",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(shipping['address_1'] ?? ''),
            if (shipping['address_2'] != null &&
                shipping['address_2'].toString().isNotEmpty)
              Text(shipping['address_2']),
            Text(
              "${shipping['city'] ?? ''}, ${shipping['state'] ?? ''} ${shipping['postcode'] ?? ''}",
            ),
            Text(shipping['country'] ?? ''),
            SizedBox(height: 4),
            Text("Phone: ${shipping['phone'] ?? 'N/A'}"),

            // Show billing email if available
            if (billing['email'] != null &&
                billing['email'].toString().isNotEmpty) ...[
              SizedBox(height: 4),
              Text("Email: ${billing['email']}"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            _buildPriceRow("Subtotal", "₹${order['discount_total'] ?? '0.00'}"),
            _buildPriceRow(
              "Discount",
              "-₹${order['discount_total'] ?? '0.00'}",
            ),
            _buildPriceRow(
              "Shipping",
              order['shipping_total'] != null &&
                      order['shipping_total'] != '0.00'
                  ? "₹${order['shipping_total']}"
                  : "FREE",
            ),
            _buildPriceRow("Tax", "₹${order['total_tax'] ?? '0.00'}"),
            Divider(height: 24),
            _buildPriceRow(
              "Total",
              "₹${order['total'] ?? '0.00'}",
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.black87 : Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);

      // List of month abbreviations
      final List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      String month = months[date.month - 1];
      String day = date.day.toString().padLeft(2, '0');
      String year = date.year.toString();

      return "$month $day, $year";
    } catch (e) {
      return "N/A";
    }
  }
}
