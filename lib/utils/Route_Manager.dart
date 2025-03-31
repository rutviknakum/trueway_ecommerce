import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/app_routes.dart';

class RouteManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Current route name
  static String _currentRoute = AppRoutes.initial;

  // Route history stack
  static List<String> _routeHistory = [AppRoutes.initial];

  // Tab history for each bottom navigation tab
  static Map<int, List<String>> _tabHistory = {
    0: [AppRoutes.home], // Home tab history
    1: [AppRoutes.categories], // Categories tab history
    2: [AppRoutes.cart], // Cart tab history
    3: [AppRoutes.settings], // Settings tab history
    4: [AppRoutes.wishlist], // Wishlist tab history
  };

  // Active tab index
  static int _activeTabIndex = 0;

  // Getters
  static String get currentRoute => _currentRoute;
  static int get activeTabIndex => _activeTabIndex;
  static List<String> get routeHistory => List.unmodifiable(_routeHistory);

  // Initialize route system
  static void init() {
    // Nothing to initialize for now
  }

  // Update current route
  static void updateCurrentRoute(String route) {
    _currentRoute = route;

    // Check if this is a tab route
    final tabIndex = AppRoutes.getIndexFromRoute(route);
    if (tabIndex != -1) {
      _activeTabIndex = tabIndex;
    }

    // Add to route history
    _routeHistory.add(route);

    // If it's a tab route, also add to tab history
    if (tabIndex != -1) {
      _tabHistory[tabIndex]?.add(route);
    }
  }

  // Navigate to a specific tab
  static void navigateToTab(BuildContext context, int tabIndex) {
    if (_activeTabIndex == tabIndex && _currentRoute == AppRoutes.main) {
      // If already on the tab, do nothing
      return;
    }

    _activeTabIndex = tabIndex;

    // Navigate to main screen with tab index
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.main,
      arguments: {'initialIndex': tabIndex},
    );
  }

  // Navigate back within the current tab
  static void navigateBackInTab(BuildContext context) {
    final history = _tabHistory[_activeTabIndex];

    if (history != null && history.length > 1) {
      // Remove current route
      history.removeLast();

      // Navigate to previous route in this tab
      final previousRoute = history.last;

      Navigator.pushReplacementNamed(context, previousRoute);
    }
  }

  // Handle system back button press
  static Future<bool> handleBackButton(BuildContext context) async {
    // If we can pop the current navigator, do that
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false; // Prevent default back behavior
    }

    // If we're on the main screen but not on the home tab, go to home tab
    if (_currentRoute == AppRoutes.main && _activeTabIndex != 0) {
      navigateToTab(context, 0);
      return false; // Prevent default back behavior
    }

    // Default behavior (allow app to close)
    return true;
  }

  // Get route observer to track navigation
  static RouteObserver<PageRoute> getRouteObserver() {
    return _RouteObserverImpl();
  }
}

// Custom RouteObserver implementation to track route changes
class _RouteObserverImpl extends RouteObserver<PageRoute> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      RouteManager.updateCurrentRoute(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      RouteManager.updateCurrentRoute(newRoute!.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      RouteManager.updateCurrentRoute(previousRoute!.settings.name!);
    }
  }
}
