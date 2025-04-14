import 'package:flutter/material.dart';

// Enhancement of the theme extensions with more consistent color definitions
extension ThemeExtensions on ThemeData {
  // Price text color - consistent across light/dark modes
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

  // Add to cart button color - consistent with primary accent color
  Color get addToCartButtonColor => const Color(0xFFFF8F00);

  // Buy now button color
  Color get buyNowButtonColor => const Color(0xFF4CAF50);

  // Active navigation color - using primary color
  Color get activeNavigationColor => primaryColor;

  // Section header color
  Color get sectionHeaderColor =>
      brightness == Brightness.light
          ? const Color(0xFF212121)
          : const Color(0xFFF5F5F5);

  // Card background color that adapts to theme
  Color get adaptiveCardColor =>
      brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

  // Text color for subtitles that adapts to theme
  Color get adaptiveSubtitleColor =>
      brightness == Brightness.light
          ? const Color(0xFF757575)
          : const Color(0xFFBDBDBD);

  // Background color for secondary surfaces
  Color get secondarySurfaceColor =>
      brightness == Brightness.light
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF2A2A2A);

  // Success color (consistent across themes)
  Color get successColor => const Color(0xFF4CAF50);

  // Warning color (consistent across themes)
  Color get warningColor => const Color(0xFFFFC107);

  // Error color (consistent across themes)
  Color get dangerColor => const Color(0xFFE53935);

  // Primary button text color (usually white in both themes)
  Color get primaryButtonTextColor => Colors.white;
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
  Color get adaptiveCardColor => Theme.of(this).adaptiveCardColor;
  Color get adaptiveSubtitleColor => Theme.of(this).adaptiveSubtitleColor;
  Color get secondarySurfaceColor => Theme.of(this).secondarySurfaceColor;
  Color get successColor => Theme.of(this).successColor;
  Color get warningColor => Theme.of(this).warningColor;
  Color get dangerColor => Theme.of(this).dangerColor;
  Color get primaryButtonTextColor => Theme.of(this).primaryButtonTextColor;

  // Is dark mode active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// Extension with standardized text styles for consistent typography
extension TextStyleExtensions on BuildContext {
  // Header text style
  TextStyle get headerTextStyle => textTheme.titleLarge!.copyWith(
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
  );

  // Title text style
  TextStyle get titleTextStyle => textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
  );

  // Subtitle text style
  TextStyle get subtitleTextStyle =>
      textTheme.bodyMedium!.copyWith(color: adaptiveSubtitleColor);

  // Details text style
  TextStyle get detailsTextStyle =>
      textTheme.bodySmall!.copyWith(color: adaptiveSubtitleColor);

  // Price text style
  TextStyle get priceTextStyle => textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.bold,
    color: priceColor,
  );
}
