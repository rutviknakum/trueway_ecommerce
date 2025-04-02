import 'package:flutter/material.dart';

// Add this to a new file: lib/config/theme_extensions.dart

// Extension on Theme to easily access custom colors and styles
extension ThemeExtensions on ThemeData {
  // Price text color
  Color get priceColor =>
      brightness == Brightness.light
          ? const Color(0xFF4CAF50)
          : const Color(0xFF66BB6A);

  // Discount badge color
  Color get discountBadgeColor => const Color(0xFFE53935);

  // In stock text color
  Color get inStockColor => const Color(0xFF4CAF50);

  // Out of stock text color
  Color get outOfStockColor => const Color(0xFFE53935);

  // Add to cart button color
  Color get addToCartButtonColor => const Color(0xFFFF8F00);

  // Buy now button color
  Color get buyNowButtonColor => const Color(0xFF4CAF50);

  // Active navigation color
  Color get activeNavigationColor => primaryColor;

  // Section header color
  Color get sectionHeaderColor =>
      brightness == Brightness.light
          ? const Color(0xFF212121)
          : const Color(0xFFF5F5F5);
}

// Extension on BuildContext to easily access theme extensions
extension ContextThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Custom theme properties
  Color get priceColor => Theme.of(this).priceColor;
  Color get discountBadgeColor => Theme.of(this).discountBadgeColor;
  Color get inStockColor => Theme.of(this).inStockColor;
  Color get outOfStockColor => Theme.of(this).outOfStockColor;
  Color get addToCartButtonColor => Theme.of(this).addToCartButtonColor;
  Color get buyNowButtonColor => Theme.of(this).buyNowButtonColor;
  Color get activeNavigationColor => Theme.of(this).activeNavigationColor;
  Color get sectionHeaderColor => Theme.of(this).sectionHeaderColor;

  // Is dark mode active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
