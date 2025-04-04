import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';
import 'package:trueway_ecommerce/services/api_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ApiService _apiService = ApiService();
  String _userName = 'Guest User';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is logged in
      final isLoggedIn = await _apiService.isLoggedIn();

      if (isLoggedIn) {
        // Get user data from ApiService
        final userData = await _apiService.getCurrentUser();

        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = 'Guest User';
          _userEmail = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Get current route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final effectiveRoute = currentRoute ?? AppRoutes.main;

    // Define drawer items
    List<Map<String, dynamic>> menuItems = [
      {'title': 'Home', 'route': AppRoutes.home, 'icon': Icons.home_outlined},
      {
        'title': 'Profile',
        'route': AppRoutes.profile,
        'icon': Icons.person_outline,
      },
      {
        'title': 'My Orders',
        'route': AppRoutes.orders,
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'title': 'Wishlist',
        'route': AppRoutes.wishlist,
        'icon': Icons.favorite_border_outlined,
      },
      {
        'title': 'Settings',
        'route': AppRoutes.settings,
        'icon': Icons.settings_outlined,
      },
    ];

    // Account-related items
    List<Map<String, dynamic>> accountItems = [
      {
        'title': 'About Us',
        'route': AppRoutes.about,
        'icon': Icons.info_outline,
      },
      {
        'title': 'Support',
        'route': AppRoutes.support,
        'icon': Icons.support_outlined,
      },
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User profile header
            _buildUserHeader(context),

            // Main menu section
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            // Main menu items
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = item['route'] == effectiveRoute;

                return _buildDrawerItem(
                  context: context,
                  title: item['title'],
                  icon: item['icon'],
                  route: item['route'],
                  isSelected: isSelected,
                );
              },
            ),

            // Account section
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCOUNT',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            // Account items
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: accountItems.length,
              itemBuilder: (context, index) {
                final item = accountItems[index];
                final isSelected = item['route'] == effectiveRoute;

                return _buildDrawerItem(
                  context: context,
                  title: item['title'],
                  icon: item['icon'],
                  route: item['route'],
                  isSelected: isSelected,
                );
              },
            ),

            // Bottom section with logout and exit
            Expanded(child: Container()),
            Divider(height: 1),
            // Sign Out Option
            _buildDrawerItem(
              context: context,
              title: 'Sign Out',
              icon: Icons.logout,
              route: '',
              isSelected: false,
              onTap: () => _handleSignOut(context),
              showTrailing: false,
            ),
            // Exit App Option
            _buildDrawerItem(
              context: context,
              title: 'Exit App',
              icon: Icons.exit_to_app,
              route: '',
              isSelected: false,
              onTap: () => _handleExit(context),
              showTrailing: false,
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Build user header with profile pic, name and email
  Widget _buildUserHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            child:
                _isLoading
                    ? CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
          ),
          SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  _userEmail.isNotEmpty ? _userEmail : 'Welcome',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_userEmail.isEmpty)
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(context, AppRoutes.login),
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
              ],
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
    VoidCallback? onTap,
    bool showTrailing = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : null,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      trailing:
          showTrailing
              ? Icon(Icons.chevron_right, size: 16, color: Colors.grey[400])
              : null,
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      onTap: onTap ?? () => _navigateToRoute(context, route),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    // Close the drawer first
    Navigator.pop(context);

    // If the route is empty, return (used for sign out and exit which have their own handlers)
    if (route.isEmpty) return;

    // Store the current route
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // If we're already on the requested route, just close the drawer
    if (route == currentRoute) {
      return;
    }

    // Handle Wishlist specifically to ensure it navigates correctly
    if (route == AppRoutes.wishlist) {
      Navigator.pushNamed(context, AppRoutes.wishlist);
      return;
    }

    // Special handling for Settings
    if (route == AppRoutes.settings) {
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
      // Use the ApiService to logout
      await _apiService.logout();

      // Update UI to show Guest User
      setState(() {
        _userName = 'Guest User';
        _userEmail = '';
      });

      // Navigate to login screen and clear the navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  // Handle exit action
  void _handleExit(BuildContext context) async {
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
          AppRoutes.login,
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
