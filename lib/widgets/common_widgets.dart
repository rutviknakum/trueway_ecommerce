// common_widgets.dart with improved theming and dark mode support
import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';
import 'package:trueway_ecommerce/config/theme_extensions.dart';

class CommonWidgets {
  // Price text with proper theme support
  static Widget buildPriceText(BuildContext context, double price) {
    return Text(
      "₹${price.toStringAsFixed(2)}",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.priceColor,
      ),
    );
  }

  // Status badge with improved theming
  static Widget buildStatusBadge(BuildContext context, String status) {
    Color statusColor = _getStatusColor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Standardized section title that works with light/dark theme
  static Widget buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.sectionHeaderColor,
        ),
      ),
    );
  }

  // Standardized header text for pages/sections
  static Widget buildHeaderText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  // Standardized subtitle text
  static Widget buildSubtitleText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  // Standardized details text
  static Widget buildDetailsText(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }

  // Primary button with consistent styling
  static Widget buildPrimaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isFullWidth = true,
    IconData? icon,
  }) {
    final buttonStyle = ThemeConfig.getPrimaryButtonStyle();

    if (icon != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: buttonStyle,
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: buttonStyle,
      ),
    );
  }

  // Helper method to get status color with theme support
  static Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.green[400]!
            : Colors.green;
      case 'processing':
        return Colors.orange;
      case 'on-hold':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
