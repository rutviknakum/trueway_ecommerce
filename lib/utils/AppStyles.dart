import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';

/// A utility class that centralizes all icons and text styles used throughout the app.
/// This ensures consistency in UI elements across all screens.
class AppStyles {
  // Private constructor to prevent instantiation
  AppStyles._();

  // ======== ICON DEFINITIONS ========
  // Navigation Icons
  static const IconData homeIcon = Icons.home;
  static const IconData categoriesIcon = Icons.category;
  static const IconData cartIcon = Icons.shopping_cart;
  static const IconData settingsIcon = Icons.settings;
  static const IconData wishlistIcon = Icons.favorite;
  static const IconData profileIcon = Icons.person;
  static const IconData searchIcon = Icons.search;
  
  // Action Icons
  static const IconData addIcon = Icons.add;
  static const IconData removeIcon = Icons.remove;
  static const IconData deleteIcon = Icons.delete;
  static const IconData editIcon = Icons.edit;
  static const IconData closeIcon = Icons.close;
  static const IconData checkIcon = Icons.check;
  static const IconData backIcon = Icons.arrow_back;
  static const IconData filterIcon = Icons.filter_list;
  static const IconData sortIcon = Icons.sort;
  static const IconData moreIcon = Icons.more_vert;
  static const IconData shareIcon = Icons.share;
  
  // Product Icons
  static const IconData favoriteIcon = Icons.favorite;
  static const IconData favoriteBorderIcon = Icons.favorite_border;
  static const IconData ratingIcon = Icons.star;
  static const IconData emptyRatingIcon = Icons.star_border;
  static const IconData halfRatingIcon = Icons.star_half;
  static const IconData addToCartIcon = Icons.add_shopping_cart;
  static const IconData notificationIcon = Icons.notifications;
  static const IconData logoutIcon = Icons.logout;
  static const IconData helpIcon = Icons.help;
  static const IconData infoIcon = Icons.info;
  
  // Payment Icons
  static const IconData creditCardIcon = Icons.credit_card;
  static const IconData cashIcon = Icons.attach_money;
  static const IconData walletIcon = Icons.account_balance_wallet;
  
  // Order Icons
  static const IconData orderHistoryIcon = Icons.receipt_long;
  static const IconData shippingIcon = Icons.local_shipping;
  static const IconData locationIcon = Icons.location_on;
  static const IconData phoneIcon = Icons.phone;
  static const IconData emailIcon = Icons.email;
  static const IconData passwordIcon = Icons.lock;
  static const IconData visibilityOnIcon = Icons.visibility;
  static const IconData visibilityOffIcon = Icons.visibility_off;
  static const IconData calendarIcon = Icons.calendar_today;

  // Image placeholder and error icons
  static const IconData imagePlaceholderIcon = Icons.image;
  static const IconData imageErrorIcon = Icons.image_not_supported;

  // ======== TEXT STYLES ========
  // Headings
  static TextStyle headingLarge(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.titleLarge?.color,
  );
  
  static TextStyle headingMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.titleMedium?.color,
  );
  
  static TextStyle headingSmall(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.titleSmall?.color,
  );

  // Subtitles
  static TextStyle subtitleLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.titleMedium?.color,
  );
  
  static TextStyle subtitleMedium(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).textTheme.titleMedium?.color,
  );
  
  static TextStyle subtitleSmall(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).textTheme.titleSmall?.color,
  );

  // Body Text
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    color: Theme.of(context).textTheme.bodyLarge?.color,
  );
  
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    color: Theme.of(context).textTheme.bodyMedium?.color,
  );
  
  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).textTheme.bodySmall?.color,
  );

  // Price Text Styles
  static TextStyle priceText(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ThemeConfig.priceColor,
  );
  
  static TextStyle discountedPriceText(BuildContext context) => TextStyle(
    fontSize: 14,
    decoration: TextDecoration.lineThrough,
    color: Theme.of(context).textTheme.bodySmall?.color,
  );
  
  static TextStyle discountPercentageText(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: ThemeConfig.discountColor,
  );

  // Status Text Styles
  static TextStyle inStockText(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.green[700],
  );
  
  static TextStyle outOfStockText(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.red[700],
  );

  // Button Text Styles
  static TextStyle buttonText(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static TextStyle linkText(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ThemeConfig.primaryColor,
  );

  // App Bar Title
  static TextStyle appBarTitle(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).appBarTheme.titleTextStyle?.color,
  );

  // Error Text
  static TextStyle errorText(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Colors.red[700],
  );

  // Helper Text
  static TextStyle helperText(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).textTheme.bodySmall?.color,
  );

  // Review Text
  static TextStyle reviewAuthorText(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.titleMedium?.color,
  );
  
  static TextStyle reviewDateText(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).textTheme.bodySmall?.color,
  );
  
  static TextStyle reviewContentText(BuildContext context) => TextStyle(
    fontSize: 14,
    color: Theme.of(context).textTheme.bodyMedium?.color,
  );

  // ======== DECORATIONS ========
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration roundedContainerDecoration(BuildContext context, {Color? color}) => BoxDecoration(
    color: color ?? Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  );
  
  static BoxDecoration inStockChipDecoration() => BoxDecoration(
    color: Colors.green[50],
    borderRadius: BorderRadius.circular(8),
  );
  
  static BoxDecoration outOfStockChipDecoration() => BoxDecoration(
    color: Colors.red[50],
    borderRadius: BorderRadius.circular(8),
  );
  
  static BoxDecoration discountTagDecoration() => BoxDecoration(
    color: ThemeConfig.discountColor,
    borderRadius: BorderRadius.circular(4),
  );
  
  // ======== PADDING ========
  static const EdgeInsets standardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0);
}
