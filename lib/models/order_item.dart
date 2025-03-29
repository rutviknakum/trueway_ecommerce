import 'package:trueway_ecommerce/models/cart_item.dart';

class OrderDetails {
  final int orderId;
  final List<CartItem> items;
  final double totalAmount;
  final String shippingMethod;
  final Map<String, String> shippingAddress;
  final double shippingCost;
  final String orderNotes;
  final DateTime orderDate;

  OrderDetails({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.shippingMethod,
    required this.shippingAddress,
    required this.shippingCost,
    required this.orderNotes,
    required this.orderDate,
  });
}
