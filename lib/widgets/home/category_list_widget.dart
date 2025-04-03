import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryListWidget extends StatefulWidget {
  final List categories;
  final Function(Map<String, dynamic>)? onCategoryTap;
  final VoidCallback? onViewAllTap;

  const CategoryListWidget({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  _CategoryListWidgetState createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends State<CategoryListWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap:
                    widget.onViewAllTap ??
                    () {
                      // Default navigation to all categories screen if no callback provided
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllCategoriesScreen(
                                categories: widget.categories,
                                onCategoryTap: widget.onCategoryTap,
                              ),
                        ),
                      );
                    },
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        // Category list
        Container(
          height: 140, // Adequate height to ensure everything fits
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              return _buildCategoryItem(category, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Call the provided callback if available
        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(category);
        }
      },
      child: Container(
        width: 90, // Wider container for better spacing and text display
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Square image container
            Container(
              height: 75, // Slightly larger image
              width: 75, // Slightly larger image
              margin: EdgeInsets.only(bottom: 8), // Space before text
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4), // Less rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
                border:
                    isSelected
                        ? Border.all(color: Colors.green, width: 2)
                        : Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    category["image"] != null &&
                            category["image"].toString().isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: category["image"],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[300]!,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.category,
                                  size: 35,
                                  color: Colors.grey[400],
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.category,
                            size: 35,
                            color: Colors.grey[400],
                          ),
                        ),
              ),
            ),
            // Text with adequate space
            Container(
              height: 36, // Taller text container to fit two lines comfortably
              child: Text(
                category["name"] ?? "",
                style: TextStyle(
                  fontSize: 13, // Slightly larger font
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate class for All Categories Screen
class AllCategoriesScreen extends StatelessWidget {
  final List categories;
  final Function(Map<String, dynamic>)? onCategoryTap;

  const AllCategoriesScreen({
    Key? key,
    required this.categories,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Categories')),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildGridItem(context, category);
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Map<String, dynamic> category) {
    // Calculate image size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth / (screenWidth > 600 ? 5 : 4)) - 16;

    return GestureDetector(
      onTap: () {
        if (onCategoryTap != null) {
          onCategoryTap!(category);
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: imageSize,
            width: imageSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  category["image"] != null &&
                          category["image"].toString().isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: category["image"],
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[300]!,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Icon(
                              Icons.category,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                      )
                      : Icon(Icons.category, size: 24, color: Colors.grey[400]),
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category["name"] ?? "",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
