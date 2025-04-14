import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';
import 'package:trueway_ecommerce/widgets/common_widgets.dart';

class OrderDetailsScreen extends StatelessWidget {
  final dynamic order;

  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    List<dynamic> lineItems = order['line_items'] ?? [];

    return Scaffold(
      backgroundColor: context.secondarySurfaceColor,
      appBar: AppBar(
        title: Text("Order #${order['id']}", style: context.titleTextStyle),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            SizedBox(height: 16),
            _buildOrderItems(context, lineItems),
            SizedBox(height: 16),
            _buildAddressCard(context),
            SizedBox(height: 16),
            _buildTotalCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    String status = order['status'] ?? 'pending';
    _getStatusColor(context, status);

    String dateCreated = order['date_created'] ?? 'N/A';
    String formattedDate = _formatDate(dateCreated);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.adaptiveCardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order Status", style: context.titleTextStyle),
                CommonWidgets.buildStatusBadge(context, status),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: context.adaptiveSubtitleColor,
                ),
                SizedBox(width: 8),
                Text(
                  "Order Date: $formattedDate",
                  style: context.detailsTextStyle,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: context.adaptiveSubtitleColor,
                ),
                SizedBox(width: 8),
                Text(
                  "Payment Method: ${order['payment_method_title'] ?? 'N/A'}",
                  style: context.detailsTextStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, List<dynamic> lineItems) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.adaptiveCardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Items", style: context.titleTextStyle),
            SizedBox(height: 12),
            lineItems.isEmpty
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No items found in this order.",
                      style: context.subtitleTextStyle,
                    ),
                  ),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: lineItems.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(color: Theme.of(context).dividerTheme.color),
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
                            border: Border.all(
                              color:
                                  Theme.of(context).dividerTheme.color ??
                                  Colors.transparent,
                            ),
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
                                            color:
                                                context.adaptiveSubtitleColor,
                                          ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.image,
                                    color: context.adaptiveSubtitleColor,
                                  ),
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
                                style: context.detailsTextStyle,
                              ),
                              SizedBox(height: 4),
                              CommonWidgets.buildPriceText(
                                context,
                                double.tryParse(item['price'].toString()) ?? 0,
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

  Widget _buildAddressCard(BuildContext context) {
    final billing = order['billing'] ?? {};
    final shipping = order['shipping'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.adaptiveCardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delivery Address", style: context.titleTextStyle),
            SizedBox(height: 12),
            Text(
              "${shipping['first_name'] ?? ''} ${shipping['last_name'] ?? ''}",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(shipping['address_1'] ?? '', style: context.detailsTextStyle),
            if (shipping['address_2'] != null &&
                shipping['address_2'].toString().isNotEmpty)
              Text(shipping['address_2'], style: context.detailsTextStyle),
            Text(
              "${shipping['city'] ?? ''}, ${shipping['state'] ?? ''} ${shipping['postcode'] ?? ''}",
              style: context.detailsTextStyle,
            ),
            Text(shipping['country'] ?? '', style: context.detailsTextStyle),
            SizedBox(height: 4),
            Text(
              "Phone: ${shipping['phone'] ?? 'N/A'}",
              style: context.detailsTextStyle,
            ),

            // Show billing email if available
            if (billing['email'] != null &&
                billing['email'].toString().isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                "Email: ${billing['email']}",
                style: context.detailsTextStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.adaptiveCardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Summary", style: context.titleTextStyle),
            SizedBox(height: 12),
            _buildPriceRow(
              context,
              "Subtotal",
              "₹${order['subtotal'] ?? '0.00'}",
            ),
            _buildPriceRow(
              context,
              "Discount",
              "-₹${order['discount_total'] ?? '0.00'}",
            ),
            _buildPriceRow(
              context,
              "Shipping",
              order['shipping_total'] != null &&
                      order['shipping_total'] != '0.00'
                  ? "₹${order['shipping_total']}"
                  : "FREE",
              valueColor:
                  order['shipping_total'] != null &&
                          order['shipping_total'] != '0.00'
                      ? null
                      : context.successColor,
            ),
            _buildPriceRow(context, "Tax", "₹${order['total_tax'] ?? '0.00'}"),
            Divider(height: 24, color: Theme.of(context).dividerTheme.color),
            _buildPriceRow(
              context,
              "Total",
              "₹${order['total'] ?? '0.00'}",
              isBold: true,
              valueColor: context.priceColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? context.titleTextStyle : context.detailsTextStyle,
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isBold ? context.priceColor : null),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status color with theme support
  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.successColor;
      case 'processing':
        return Colors.orange;
      case 'on-hold':
        return Colors.blue;
      case 'cancelled':
        return context.dangerColor;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
