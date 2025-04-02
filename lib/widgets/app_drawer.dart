import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get the current route name
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.main;

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
                  currentRoute,
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
          _buildDrawerItem(
            context: context,
            title: 'Exit App',
            icon: Icons.exit_to_app,
            route: AppRoutes.main,
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
    if (currentRoute == AppRoutes.main) {
      // If we're on the main screen, determine selected tab based on route index
      final targetIndex = AppRoutes.getIndexFromRoute(route);
      return targetIndex == currentIndex;
    }

    // Direct route comparison
    return route == currentRoute;
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: isSelected ? primaryColor : null, size: 24),
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
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap:
          onTap ??
          () {
            // Close the drawer
            Navigator.pop(context);

            // If we're navigating to a tab in the bottom navigation
            if (AppRoutes.getIndexFromRoute(route) != -1) {
              // Navigate to the tab via the AppRoutes utility
              AppRoutes.navigateToTab(
                context,
                AppRoutes.getIndexFromRoute(route),
              );
            } else {
              // Navigate to other screens directly
              Navigator.pushNamed(context, route);
            }
          },
    );
  }

  // Handle exit action
  void _handleExit(BuildContext context) async {
    // Show confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Return to home screen?'),
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
      // Navigate to home screen and clear the stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    }
  }
}
