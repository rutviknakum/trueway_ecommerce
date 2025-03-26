import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/Setting_screen.dart';
import 'package:trueway_ecommerce/screens/WishlistScreen.dart';
import 'package:trueway_ecommerce/screens/categories_screen.dart';
import 'package:trueway_ecommerce/screens/home_screen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/splash_screen.dart';
import 'package:trueway_ecommerce/widgets/bottom_navigation_bar.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> wishlist = []; // Store wishlist in MainScreen

  void toggleWishlist(Map<String, dynamic> product) {
    setState(() {
      final isWishlisted = wishlist.any((item) => item["id"] == product["id"]);

      if (isWishlisted) {
        wishlist.removeWhere((item) => item["id"] == product["id"]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product['name']} removed from Wishlist")),
        );
      } else {
        wishlist.add(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product['name']} added to Wishlist")),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      CategoriesScreen(),
      CartScreen(),
      SettingsScreen(),
      WishlistScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
