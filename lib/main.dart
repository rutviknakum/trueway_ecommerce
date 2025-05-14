import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trueway_ecommerce/utils/network_permission_helper.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RouteManager.init();
  
  // Run the app first to establish a proper context
  runApp(MyApp());
  
  // Request permissions after app is initialized
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Allow UI to render first
    await Future.delayed(Duration(milliseconds: 300));
    
    // Trigger iOS network permission dialog
    if (Platform.isIOS) {
      await NetworkPermissionHelper.triggerLocalNetworkPermissionDialog();
      
      // Show instructions dialog after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        _showNetworkPermissionInstructions();
      });
    } else {
      // For non-iOS platforms, just request general permissions
      await _requestPermissions();
    }
  });
}

Future<void> _requestPermissions() async {
  // Actively trigger the iOS local network permission dialog
  await NetworkPermissionHelper.triggerLocalNetworkPermissionDialog();
  
  // Also request location permissions if needed
  if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  }
  
  // The dialog is now shown from the main method after app initialization
}

// Show dialog with instructions for enabling network permissions
void _showNetworkPermissionInstructions() {
  final context = RouteManager.navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Network Permissions Required'),
        content: Text(
          'This app requires local network permissions for development features.\n\n'
          'Please enable "Local Network" in your device settings for this app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
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
