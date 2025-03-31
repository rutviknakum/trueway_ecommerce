import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/AddressScreen.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/PaymentScreen.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/PreviewScreen.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/ShippingScreen.dart';
import 'package:trueway_ecommerce/screens/Order_scrren/OrderConfirmationScreen.dart';
import 'package:trueway_ecommerce/screens/Order_scrren/OrderDetailsScreen.dart';
import 'package:trueway_ecommerce/screens/Order_scrren/OrderHistoryScreen.dart';

// Import all screens
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/Setting_screen.dart';
import 'package:trueway_ecommerce/screens/WishlistScreen.dart';
import 'package:trueway_ecommerce/screens/categories_screen.dart';
import 'package:trueway_ecommerce/screens/login_screen.dart';
import 'package:trueway_ecommerce/screens/main_screen.dart';
import 'package:trueway_ecommerce/screens/onboarding_screen.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/screens/product_list_screen.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/signup_screen.dart';
import 'package:trueway_ecommerce/screens/splash_screen.dart';
import 'package:trueway_ecommerce/screens/profile_screen.dart'; // Add this import

/// A utility class that defines all routes for the application
/// This class cannot be instantiated.
class AppRoutes {
  // This class is not meant to be instantiated or extended - private constructor
  AppRoutes._();

  // Route names as static constants
  static const String main = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String wishlist = '/wishlist';

  // Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';

  // Product routes
  static const String productDetails = '/product-details';
  static const String productList = '/product-list';

  // Checkout routes
  static const String checkout = '/checkout';
  static const String address = '/checkout/address';
  static const String shipping = '/checkout/shipping';
  static const String preview = '/checkout/preview';
  static const String payment = '/checkout/payment';
  static const String orderConfirmation = '/order-confirmation';

  // User routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  // Order routes
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';

  // Additional routes
  static const String allProducts = '/products';
  static const String offers = '/offers';
  static const String about = '/about';
  static const String support = '/support';
  static const String logout = '/logout'; // For handling logout action

  // Initial route
  static const String initial = splash;

  // Define the routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(),
      onboarding: (context) => OnboardingScreen(),
      main: (context) => MainScreen(),
      home: (context) => MainScreen(),
      cart: (context) => CartScreen(),
      categories: (context) => CategoriesScreen(),
      settings: (context) => SettingsScreen(),
      wishlist: (context) => WishlistScreen(),
      search: (context) => SearchScreen(),
      orders: (context) => OrderHistoryScreen(),
      login: (context) => LoginScreen(),
      signup: (context) => SignupScreen(),
      address: (context) => AddressScreen(),
      profile: (context) => ProfileScreen(), // Add this route
      // Not defining routes for screens that require parameters
      // Those are handled in generateRoute
    };
  }

  // Error route for undefined routes
  static Route<dynamic> errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Route not found!')),
        );
      },
    );
  }

  // For handling routes that need parameters
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case profile:
        // Handle profile route with direct navigation
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen(),
        );

      case profileEdit:
        // Handle profile edit with parameters if needed

        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) =>
                  ProfileScreen(), // You could create a separate EditProfileScreen if needed
        );

      case productDetails:
        // Get the product from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final product = args?['product'];

        if (product != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ProductDetailsScreen(product: product),
          );
        }
        return errorRoute();

      case productList:
        final args = settings.arguments as Map<String, dynamic>?;
        final title = args?['title'] ?? '';
        final products = args?['products'] ?? [];
        final onProductTap = args?['onProductTap'];

        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => ProductListScreen(
                title: title,
                products: products,
                onProductTap: onProductTap,
              ),
        );

      case shipping:
        final args = settings.arguments as Map<String, dynamic>?;
        final shippingAddress =
            args?['shippingAddress'] as Map<String, String>?;

        if (shippingAddress != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ShippingScreen(shippingAddress: shippingAddress),
          );
        }
        return errorRoute();

      case preview:
        final args = settings.arguments as Map<String, dynamic>?;
        final shippingAddress =
            args?['shippingAddress'] as Map<String, String>?;
        final shippingMethod = args?['shippingMethod'] as String?;
        final shippingCost = args?['shippingCost'] as double?;

        if (shippingAddress != null &&
            shippingMethod != null &&
            shippingCost != null) {
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => PreviewScreen(
                  shippingAddress: shippingAddress,
                  shippingMethod: shippingMethod,
                  shippingCost: shippingCost,
                ),
          );
        }
        return errorRoute();

      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        final shippingAddress =
            args?['shippingAddress'] as Map<String, String>?;
        final shippingMethod = args?['shippingMethod'] as String?;
        final shippingCost = args?['shippingCost'] as double?;
        final orderNotes = args?['orderNotes'] as String?;

        if (shippingAddress != null &&
            shippingMethod != null &&
            shippingCost != null &&
            orderNotes != null) {
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => PaymentScreen(
                  shippingAddress: shippingAddress,
                  shippingMethod: shippingMethod,
                  shippingCost: shippingCost,
                  orderNotes: orderNotes,
                ),
          );
        }
        return errorRoute();

      case orderConfirmation:
        final args = settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'];
        final finalPrice = args?['finalPrice'] as double?;

        if (orderId != null && finalPrice != null) {
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => OrderConfirmationScreen(
                  orderId: orderId,
                  finalPrice: finalPrice,
                ),
          );
        }
        return errorRoute();

      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final order = args?['order'];

        if (order != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => OrderDetailsScreen(order: order),
          );
        }
        return errorRoute();

      case logout:
        // Handle logout logic here or redirect to login
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginScreen(),
        );

      default:
        // If the route is not defined, show an error page
        return errorRoute();
    }
  }

  // Get the index of a route in the bottom navigation
  static int getIndexFromRoute(String route) {
    switch (route) {
      case home:
        return 0;
      case categories:
        return 1;
      case cart:
        return 2;
      case settings:
        return 3;
      case wishlist:
        return 4;
      default:
        return -1; // Not a tab route
    }
  }

  // Get the route from an index in the bottom navigation
  static String getRouteFromIndex(int index) {
    switch (index) {
      case 0:
        return home;
      case 1:
        return categories;
      case 2:
        return cart;
      case 3:
        return settings;
      case 4:
        return wishlist;
      default:
        return home;
    }
  }

  // Navigate between bottom nav items
  static void navigateToTab(BuildContext context, int index) {
    if (ModalRoute.of(context)?.settings.name == main) {
      // If we're on the main screen, we can just update the selected index
      // This will be handled by the MainScreen
      Navigator.pushReplacementNamed(
        context,
        main,
        arguments: {'initialIndex': index},
      );
    } else {
      // Otherwise navigate to the main screen with the desired index
      Navigator.pushNamedAndRemoveUntil(
        context,
        main,
        (route) => false,
        arguments: {'initialIndex': index},
      );
    }
  }
}
