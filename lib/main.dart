import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      Future.delayed(Duration(milliseconds: 500), () async {
        await _ensurePermissionsGranted();
      });
    } else {
      // For non-iOS platforms, request and ensure permissions are granted
      await _ensurePermissionsGranted();
    }
  });
}

Future<PermissionStatus> _requestPermissions() async {
  // Actively trigger the iOS local network permission dialog
  await NetworkPermissionHelper.triggerLocalNetworkPermissionDialog();
  
  // Request location permissions
  var status = await Permission.locationWhenInUse.request();
  return status;
}

// This function ensures that permissions are granted before proceeding
// Check if running in a simulator
bool get _isSimulator {
  if (Platform.isAndroid) return false; // Android emulators don't have this issue
  if (Platform.isIOS) {
    // Simple check for iOS simulator based on device model identifier
    return !kReleaseMode && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  }
  return false;
}

Future<void> _ensurePermissionsGranted() async {
  bool permissionsGranted = false;
  
  // If we're in a simulator, show a single dialog and then proceed
  if (_isSimulator) {
    debugPrint('Running in iOS Simulator - bypassing actual permission requests');
    
    // Show a simulator-specific dialog
    await _showSimulatorPermissionDialog();
    
    // Always consider permissions granted in simulator if user clicks OK
    return;
  }
  
  // Real device flow
  while (!permissionsGranted) {
    // Check if permissions are already granted
    PermissionStatus locationStatus = await Permission.locationWhenInUse.status;
    
    if (locationStatus.isGranted) {
      permissionsGranted = true;
      break;
    }
    
    // Show custom permission dialog first
    bool shouldAllowPermission = await _showCustomPermissionDialog();
    
    if (shouldAllowPermission) {
      // If user clicked "Allow", proceed with requesting actual permission
      if (Platform.isIOS) {
        // For iOS, show system settings dialog if needed
        await _showNetworkPermissionInstructions(allowDismiss: false);
        
        // Then request the actual permission
        PermissionStatus result = await _requestPermissions();
        
        if (result.isGranted) {
          permissionsGranted = true;
        }
      } else {
        // For Android, directly request permissions
        PermissionStatus result = await _requestPermissions();
        
        // If user denied with "Don't ask again", show settings dialog
        if (result.isPermanentlyDenied) {
          await _showPermissionSettingsDialog();
        } else if (result.isGranted) {
          permissionsGranted = true;
        }
      }
    } else {
      // User clicked "Not Allow" - show explanation about why it's needed
      await _showPermissionRequiredDialog();
      // Continue the loop to show the dialog again
    }
    
    // Small delay before checking again
    await Future.delayed(Duration(milliseconds: 500));
  }
}

// Show dialog with instructions for enabling network permissions
Future<void> _showNetworkPermissionInstructions({bool allowDismiss = true}) async {
  final context = RouteManager.navigatorKey.currentContext;
  if (context != null) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Network Permissions Required'),
        content: Text(
          'This app requires local network permissions for development features.\n\n'
          'Please enable "Local Network" in your device settings for this app.'),
        actions: [
          if (allowDismiss)
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

// Custom permission dialog with Allow and Not Allow buttons
Future<bool> _showCustomPermissionDialog() async {
  final context = RouteManager.navigatorKey.currentContext;
  if (context == null) return false;
  
  bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('Permission Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 50,
            color: Theme.of(ctx).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'This app requires access to your location to provide you with accurate services and features.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Please allow location access to continue using all features of the app.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
          ),
          child: Text('Not Allow', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Allow', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  
  // Return false if dialog was dismissed without selection
  return result ?? false;
}

// Dialog specifically for simulator environments
Future<bool> _showSimulatorPermissionDialog() async {
  final context = RouteManager.navigatorKey.currentContext;
  if (context == null) return false;
  
  bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('Simulator Environment Detected'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.developer_mode,
            size: 50,
            color: Theme.of(ctx).primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'You are running in a simulator environment where permission dialogs may not work properly.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Permissions will be automatically granted for testing purposes.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  
  return result ?? false;
}

// Dialog that appears when user selects "Not Allow"
Future<void> _showPermissionRequiredDialog() async {
  final context = RouteManager.navigatorKey.currentContext;
  if (context != null) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'This application requires location permission to function properly. '
          'Without this permission, some features may not work correctly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('I Understand'),
          ),
        ],
      ),
    );
  }
}


// Show dialog to direct user to settings when they've selected 'Don't ask again'
Future<void> _showPermissionSettingsDialog() async {
  final context = RouteManager.navigatorKey.currentContext;
  if (context != null) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Location permission is required for this app to function properly. '
          'Please enable it in your device settings.'),
        actions: [
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
