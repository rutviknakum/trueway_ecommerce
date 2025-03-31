import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  // Define navigation items with their respective routes
  final List<Map<String, dynamic>> _navItems = [
    {
      'route': AppRoutes.home,
      'label': 'Home',
      'activeIcon': Icons.home,
      'inactiveIcon': Icons.home_outlined,
    },
    {
      'route': AppRoutes.categories,
      'label': 'Categories',
      'activeIcon': Icons.category,
      'inactiveIcon': Icons.category_outlined,
    },
    {
      'route': AppRoutes.cart,
      'label': 'Cart',
      'activeIcon': Icons.shopping_cart,
      'inactiveIcon': Icons.shopping_cart_outlined,
      'badge': 0, // This will be updated dynamically
    },
    {
      'route': AppRoutes.settings,
      'label': 'Settings',
      'activeIcon': Icons.settings,
      'inactiveIcon': Icons.settings_outlined,
    },
    {
      'route': AppRoutes.wishlist,
      'label': 'Wishlist',
      'activeIcon': Icons.favorite,
      'inactiveIcon': Icons.favorite_border_outlined,
      'badge': 0, // This will be updated dynamically
    },
  ];

  // Getters
  int get currentIndex => _currentIndex;
  List<Map<String, dynamic>> get navItems => _navItems;
  String get currentRoute => _navItems[_currentIndex]['route'];

  // Methods
  void setCurrentIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void navigateToRoute(BuildContext context, String route) {
    final index = _navItems.indexWhere((item) => item['route'] == route);
    if (index != -1) {
      setCurrentIndex(index);
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  // Update badge count for a specific item
  void updateBadgeCount(String route, int count) {
    final index = _navItems.indexWhere((item) => item['route'] == route);
    if (index != -1 && _navItems[index].containsKey('badge')) {
      _navItems[index]['badge'] = count > 0 ? count : null;
      notifyListeners();
    }
  }

  // Update cart badge count specifically
  void updateCartBadge(int count) {
    updateBadgeCount(AppRoutes.cart, count);
  }

  // Update wishlist badge count specifically
  void updateWishlistBadge(int count) {
    updateBadgeCount(AppRoutes.wishlist, count);
  }
}
