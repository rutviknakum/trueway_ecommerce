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
      // Give the app a moment to initialize fully
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use our comprehensive NetworkPermissionHelper to trigger the dialog
      await NetworkPermissionHelper.triggerLocalNetworkPermissionDialog();

      // After dialog is triggered, show a custom dialog explaining what to do
      if (!(await NetworkPermissionHelper.hasGrantedPermission())) {
        // This should run on a real device/simulator to show the permission dialog
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
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Network Permission Required'),
        content: const Text(
          'This app needs local network permission to function properly. '
          'Please tap "Open Settings" and enable Local Network in the app permissions.',
        ),
        actions: [
          TextButton(
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
          TextButton(
            child: const Text('Later'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Simple function to request location permission
Future<PermissionStatus> requestLocationPermission() async {
  return await Permission.locationWhenInUse.request();
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
