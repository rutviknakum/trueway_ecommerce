import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/AppStyles.dart';

/// This is an example file showing how to implement the AppStyles utility
/// throughout your application for consistent UX.
class StyleGuideExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use consistent AppBar title style
        title: Text('Style Guide', style: AppStyles.appBarTitle(context)),
        // Use predefined icons
        leading: IconButton(
          icon: Icon(AppStyles.backIcon),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(AppStyles.searchIcon),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(AppStyles.cartIcon),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.standardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headings demonstration
            Text('Heading Large', style: AppStyles.headingLarge(context)),
            SizedBox(height: 8),
            Text('Heading Medium', style: AppStyles.headingMedium(context)),
            SizedBox(height: 8),
            Text('Heading Small', style: AppStyles.headingSmall(context)),
            
            Divider(height: 32),
            
            // Subtitles demonstration
            Text('Subtitle Large', style: AppStyles.subtitleLarge(context)),
            SizedBox(height: 8),
            Text('Subtitle Medium', style: AppStyles.subtitleMedium(context)),
            SizedBox(height: 8),
            Text('Subtitle Small', style: AppStyles.subtitleSmall(context)),
            
            Divider(height: 32),
            
            // Body text demonstration
            Text('Body Large Text for longer content', style: AppStyles.bodyLarge(context)),
            SizedBox(height: 8),
            Text('Body Medium Text for regular content', style: AppStyles.bodyMedium(context)),
            SizedBox(height: 8),
            Text('Body Small Text for less important content', style: AppStyles.bodySmall(context)),
            
            Divider(height: 32),
            
            // Price styles demonstration
            Row(
              children: [
                Text('₹1,299', style: AppStyles.priceText(context)),
                SizedBox(width: 8),
                Text('₹1,599', style: AppStyles.discountedPriceText(context)),
                SizedBox(width: 8),
                Container(
                  padding: AppStyles.chipPadding,
                  decoration: AppStyles.discountTagDecoration(),
                  child: Text('20% OFF', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            
            Divider(height: 32),
            
            // Status indicators
            Row(
              children: [
                Container(
                  padding: AppStyles.chipPadding,
                  decoration: AppStyles.inStockChipDecoration(),
                  child: Text('In Stock', style: AppStyles.inStockText(context)),
                ),
                SizedBox(width: 16),
                Container(
                  padding: AppStyles.chipPadding,
                  decoration: AppStyles.outOfStockChipDecoration(),
                  child: Text('Out of Stock', style: AppStyles.outOfStockText(context)),
                ),
              ],
            ),
            
            Divider(height: 32),
            
            // Icons demonstration
            Text('Common Icons', style: AppStyles.subtitleLarge(context)),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildIconExample(context, 'Home', AppStyles.homeIcon),
                _buildIconExample(context, 'Cart', AppStyles.cartIcon),
                _buildIconExample(context, 'Wishlist', AppStyles.wishlistIcon),
                _buildIconExample(context, 'Search', AppStyles.searchIcon),
                _buildIconExample(context, 'Settings', AppStyles.settingsIcon),
                _buildIconExample(context, 'Profile', AppStyles.profileIcon),
                _buildIconExample(context, 'Add', AppStyles.addIcon),
                _buildIconExample(context, 'Remove', AppStyles.removeIcon),
                _buildIconExample(context, 'Delete', AppStyles.deleteIcon),
                _buildIconExample(context, 'Edit', AppStyles.editIcon),
                _buildIconExample(context, 'Rating', AppStyles.ratingIcon),
                _buildIconExample(context, 'Filter', AppStyles.filterIcon),
                _buildIconExample(context, 'Sort', AppStyles.sortIcon),
                _buildIconExample(context, 'Share', AppStyles.shareIcon),
              ],
            ),
            
            Divider(height: 32),
            
            // Buttons demonstration
            Text('Buttons', style: AppStyles.subtitleLarge(context)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Primary Button', style: AppStyles.buttonText(context)),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: Text('Text Button', style: AppStyles.linkText(context)),
            ),
            
            Divider(height: 32),
            
            // Card demonstration
            Text('Card Example', style: AppStyles.subtitleLarge(context)),
            SizedBox(height: 16),
            Container(
              padding: AppStyles.cardPadding,
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Title', style: AppStyles.subtitleMedium(context)),
                  SizedBox(height: 8),
                  Text(
                    'This is a sample product description that shows how text styles can be applied consistently.',
                    style: AppStyles.bodyMedium(context),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('₹999', style: AppStyles.priceText(context)),
                      Spacer(),
                      Icon(AppStyles.addToCartIcon, color: Theme.of(context).primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIconExample(BuildContext context, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        SizedBox(height: 4),
        Text(label, style: AppStyles.bodySmall(context)),
      ],
    );
  }
}
