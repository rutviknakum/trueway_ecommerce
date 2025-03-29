import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/models/order_item.dart';

class OrderProvider with ChangeNotifier {
  List<OrderDetails> _orders = [];
  OrderDetails? _lastOrder;

  List<OrderDetails> get orders => _orders;
  OrderDetails? get lastOrder => _lastOrder;

  void addOrder({
    required int orderId,
    required List<CartItem> items,
    required double totalAmount,
    required String shippingMethod,
    required Map<String, String> shippingAddress,
    required double shippingCost,
    required String orderNotes,
  }) {
    final newOrder = OrderDetails(
      orderId: orderId,
      items: List.from(items), // Create a deep copy of the items
      totalAmount: totalAmount,
      shippingMethod: shippingMethod,
      shippingAddress: Map.from(shippingAddress),
      shippingCost: shippingCost,
      orderNotes: orderNotes,
      orderDate: DateTime.now(),
    );

    _orders.add(newOrder);
    _lastOrder = newOrder; // Save as the last order
    notifyListeners();
  }

  void clearLastOrder() {
    _lastOrder = null;
    notifyListeners();
  }
}
