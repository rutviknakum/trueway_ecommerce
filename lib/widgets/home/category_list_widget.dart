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
        // Category section header with improved styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              InkWell(
                onTap: widget.onViewAllTap ?? 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllCategoriesScreen(
                          categories: widget.categories,
                          onCategoryTap: widget.onCategoryTap,
                        ),
                      ),
                    );
                  },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Improved category list with better spacing
        Container(
          height: 135, // Optimized height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            physics: BouncingScrollPhysics(),
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
    
    // Safely extract image URL with proper null handling and type checking
    String? imageUrl;
    if (category['image'] != null) {
      if (category['image'] is Map && category['image']['src'] != null) {
        imageUrl = category['image']['src'].toString();
      } else if (category['image'] is String) {
        imageUrl = category['image'].toString();
      }
    }

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
        width: 95, // Slightly wider for better spacing
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category image with improved container
            Container(
              height: 80,
              width: 80,
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: Colors.green, width: 2)
                    : Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
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
      appBar: AppBar(
        title: Text('All Categories'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
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
    final imageSize = (screenWidth / (screenWidth > 600 ? 5 : 4)) - 20;
    
    // Safely extract image URL with proper null handling and type checking
    String? imageUrl;
    if (category['image'] != null) {
      if (category['image'] is Map && category['image']['src'] != null) {
        imageUrl = category['image']['src'].toString();
      } else if (category['image'] is String) {
        imageUrl = category['image'].toString();
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onCategoryTap != null) {
            onCategoryTap!(category);
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Container with improved styling
              Container(
                height: imageSize,
                width: imageSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Icon(
                                Icons.category,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: Icon(
                              Icons.category,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8),
              // Text with better styling
              Container(
                height: 36, // Fixed height
                width: double.infinity,
                child: Center(
                  child: Text(
                    category["name"] ?? "Category",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
