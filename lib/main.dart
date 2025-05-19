import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trueway_ecommerce/providers/auth_provider.dart';
import 'package:trueway_ecommerce/providers/navigation_provider.dart';
import 'package:trueway_ecommerce/providers/order_provider.dart';
import 'package:trueway_ecommerce/providers/user_provider.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';
import 'package:trueway_ecommerce/utils/route_manager.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';
import 'package:trueway_ecommerce/utils/network_permission_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RouteManager.init();
  
  // Run the app first to establish a proper context
  runApp(MyApp());
  
  // Initialize network permissions - iOS only
  if (Platform.isIOS) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Give the app a moment to initialize fully before triggering permission dialog
      await Future.delayed(const Duration(seconds: 1));
      
      // Request location permission first to ensure iOS permission system is active
      await requestLocationPermission();
      
      // Pause briefly before triggering network permission
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use our comprehensive NetworkPermissionHelper to trigger the dialog
      await NetworkPermissionHelper.triggerLocalNetworkPermissionDialog();

      // Wait a bit for the system dialog to either appear or disappear
      await Future.delayed(const Duration(seconds: 2));
      
      // After dialog is triggered, show our custom dialog explaining what to do
      if (!(await NetworkPermissionHelper.hasGrantedPermission())) {
        // This should run on a real device/simulator to show the custom dialog
        _showNetworkPermissionInstructionDialog();
      }
    });
  }
}

// Shows a helpful UI dialog explaining to the user what to do about network permissions
void _showNetworkPermissionInstructionDialog() {
  // Get the navigator key to show dialog without context
  final context = RouteManager.navigatorKey.currentContext;
  if (context == null) return;
  
  // Show a more detailed and visually appealing dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.blue),
            const SizedBox(width: 10),
            const Text('Network Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app needs local network permission to function properly in debug mode.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Please follow these steps:'),
            const SizedBox(height: 8),
            _bulletPoint('1. Tap "Open Settings" below'),
            _bulletPoint('2. Scroll down to this app'),
            _bulletPoint('3. Enable "Local Network" permission'),
            _bulletPoint('4. Return to the app'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.yellow.shade100,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This permission is only needed during development.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Later'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
            onPressed: () {
              // Close dialog
              Navigator.of(context).pop();
              // Open settings
              openAppSettings();
              // Mark as granted to avoid showing dialog again
              NetworkPermissionHelper.markPermissionGranted();
            },
          ),
        ],
      );
    },
  );
}

// Simple function to request location permission
Future<PermissionStatus> requestLocationPermission() async {
  try {
    // First check if we already have permission to avoid unnecessary prompts
    if (await Permission.locationWhenInUse.isGranted) {
      return PermissionStatus.granted;
    }
    return await Permission.locationWhenInUse.request();
  } catch (e) {
    debugPrint('Error requesting location permission: $e');
    return PermissionStatus.denied;
  }
}

// Helper to create a bullet point list item
Widget _bulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        const Text('•', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}










class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => OrderProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ChangeNotifierProvider(create: (ctx) => NavigationProvider()),
        ChangeNotifierProvider(create: (ctx) => WishlistProvider()),
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) {
          return MaterialApp(
            title: 'Trueway E-Commerce',
            debugShowCheckedModeBanner: false,

            // Use ThemeConfig for light theme
            theme: ThemeConfig.lightTheme,

            // Use ThemeConfig for dark theme
            darkTheme: ThemeConfig.darkTheme,

            // Use the theme mode from your provider
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // Set up route system
            initialRoute: AppRoutes.initial,
            navigatorKey: RouteManager.navigatorKey,
            navigatorObservers: [RouteManager.getRouteObserver()],

            // Define static routes
            routes: AppRoutes.getRoutes(),

            // Dynamic route handling
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
