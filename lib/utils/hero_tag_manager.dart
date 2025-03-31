import 'package:trueway_ecommerce/utils/route_manager.dart';

class HeroTagManager {
  // Singleton pattern
  static final HeroTagManager _instance = HeroTagManager._internal();

  factory HeroTagManager() {
    return _instance;
  }

  HeroTagManager._internal();

  // Generate unique hero tags based on route, screen and identifier
  String getUniqueTag(String id, String type) {
    // Include the current route and active tab in the tag to ensure uniqueness
    final currentRoute = RouteManager.currentRoute;
    final activeTab = RouteManager.activeTabIndex.toString();

    return '$currentRoute-$activeTab-$type-$id';
  }

  // Product-specific hero tags
  String getProductImageTag(String productId) {
    return getUniqueTag(productId, 'product-image');
  }

  String getProductTitleTag(String productId) {
    return getUniqueTag(productId, 'product-title');
  }

  String getProductPriceTag(String productId) {
    return getUniqueTag(productId, 'product-price');
  }

  // Category-specific hero tags
  String getCategoryImageTag(String categoryId) {
    return getUniqueTag(categoryId, 'category-image');
  }

  String getCategoryTitleTag(String categoryId) {
    return getUniqueTag(categoryId, 'category-title');
  }
}
