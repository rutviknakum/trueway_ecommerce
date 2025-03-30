import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryListWidget extends StatefulWidget {
  final List categories;

  const CategoryListWidget({Key? key, required this.categories})
    : super(key: key);

  @override
  _CategoryListWidgetState createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends State<CategoryListWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return SizedBox.shrink();

    return Container(
      height: 90, // Fixed height container to prevent overflow
      margin: EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          return _buildCategoryItem(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // In a real app, we would navigate or filter products
      },
      child: Container(
        width: 70,
        margin: EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            Container(
              height: 55, // Fixed height for image
              width: 55, // Fixed width for image
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    category["image"] != null &&
                            category["image"].toString().isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: category["image"],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
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
                                size: 30,
                                color: Colors.grey[400],
                              ),
                        )
                        : Icon(
                          Icons.category,
                          size: 25,
                          color: Colors.grey[400],
                        ),
              ),
            ),
            SizedBox(height: 3), // Reduced space
            // Fixed height text to prevent layout shifts
            Container(
              height: 26, // Fixed height for text (accommodates 2 lines)
              child: Text(
                category["name"] ?? "",
                style: TextStyle(
                  fontSize: 11, // Smaller font
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.orange : Colors.black87,
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
