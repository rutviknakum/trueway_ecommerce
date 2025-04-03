import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get the current route name - ensure we get the actual route, not just the parent
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final effectiveRoute = currentRoute ?? AppRoutes.main;

    // Log for debugging
    print('Current route: $effectiveRoute');

    // Extract the selected index from route arguments (if available)
    int currentIndex = 0;
    if (currentRoute == AppRoutes.main) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      currentIndex = args?['initialIndex'] as int? ?? 0;
    }

    // Define drawer items with their respective routes and icons
    List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Home',
        'route': AppRoutes.home,
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home,
      },
      {
        'title': 'Profile',
        'route': AppRoutes.profile,
        'icon': Icons.person_outline,
        'selectedIcon': Icons.person,
      },
      {
        'title': 'My Orders',
        'route': AppRoutes.orders,
        'icon': Icons.shopping_bag_outlined,
        'selectedIcon': Icons.shopping_bag,
      },
      {
        'title': 'Wishlist',
        'route': AppRoutes.wishlist,
        'icon': Icons.favorite_border_outlined,
        'selectedIcon': Icons.favorite,
      },
      {
        'title': 'Settings',
        'route': AppRoutes.settings,
        'icon': Icons.settings_outlined,
        'selectedIcon': Icons.settings,
      },
      {
        'title': 'About Us',
        'route': AppRoutes.about,
        'icon': Icons.info_outline,
        'selectedIcon': Icons.info,
      },
      {
        'title': 'Support',
        'route': AppRoutes.support,
        'icon': Icons.support_outlined,
        'selectedIcon': Icons.support,
      },
    ];

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context, isDarkMode),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _isRouteSelected(
                  item['route'],
                  effectiveRoute,
                  currentIndex,
                );

                return _buildDrawerItem(
                  context: context,
                  title: item['title'],
                  icon: isSelected ? item['selectedIcon'] : item['icon'],
                  route: item['route'],
                  isSelected: isSelected,
                  badge: item['badge'],
                );
              },
            ),
          ),
          Divider(),
          // Sign Out Option
          _buildDrawerItem(
            context: context,
            title: 'Sign Out',
            icon: Icons.logout,
            route: '',
            isSelected: false,
            onTap: () => _handleSignOut(context),
          ),
          // Exit App Option
          _buildDrawerItem(
            context: context,
            title: 'Exit App',
            icon: Icons.exit_to_app,
            route: '',
            isSelected: false,
            onTap: () => _handleExit(context),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // Check if the route is selected based on current route
  bool _isRouteSelected(String route, String currentRoute, int currentIndex) {
    // Since we're removing all highlighting, always return false
    return false;
  }

  // Build the drawer header with user info
  Widget _buildDrawerHeader(BuildContext context, bool isDarkMode) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        image: DecorationImage(
          image: AssetImage('assets/images/drawer_header_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),
          Text('Welcome', style: TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            'Guest User', // Generic user name
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Build individual drawer item
  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required bool isSelected,
    int? badge,
    VoidCallback? onTap,
  }) {
    // Use default colors with no highlighting
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24),
          if (badge != null)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(title),
      selected: false, // Never show as selected
      onTap: onTap ?? () => _navigateToRoute(context, route),
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    // Store the current route before closing the drawer
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Debug print for navigation
    print('Navigating from $currentRoute to $route');

    // If we're already on the requested route, just close the drawer
    if (route == currentRoute) {
      Navigator.pop(context);
      return;
    }

    // Close the drawer first
    Navigator.pop(context);

    // If the route is empty, return (used for sign out and exit which have their own handlers)
    if (route.isEmpty) return;

    // Handle Wishlist specifically to ensure it navigates correctly
    if (route == AppRoutes.wishlist) {
      // Direct navigation to the Wishlist screen
      Navigator.pushNamed(context, AppRoutes.wishlist);
      return;
    }

    // Special handling for Settings - handle as both tab and separate screen
    if (route == AppRoutes.settings) {
      // Navigate to Settings screen directly
      Navigator.pushNamed(context, AppRoutes.settings);
      return;
    }

    // For bottom navigation tabs
    final targetIndex = AppRoutes.getIndexFromRoute(route);
    if (targetIndex != -1) {
      // Navigate to the main screen with the specific tab index
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (r) => false,
        arguments: {'initialIndex': targetIndex},
      );
    } else {
      // For other screens, use simple navigation to maintain the back stack
      Navigator.pushNamed(context, route);
    }
  }

  // Handle sign out action
  void _handleSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sign Out'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );

    if (shouldSignOut == true) {
      // TODO: Implement your sign-out logic here
      // For example:
      // AuthService.signOut();

      // Navigate to login screen and clear the navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login, // Assuming AppRoutes.login is your login route
        (route) => false,
      );
    }
  }

  // Handle exit action
  void _handleExit(BuildContext context) async {
    // Show confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );

    // If user confirmed exit
    if (shouldExit == true) {
      // Close the app - handle different platforms
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      } else {
        // For web or desktop or fallback
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login, // Redirect to login screen before attempting to exit
          (route) => false,
        );
        // Try to close after a short delay
        Future.delayed(Duration(milliseconds: 300), () {
          SystemNavigator.pop();
        });
      }
    }
  }
}
