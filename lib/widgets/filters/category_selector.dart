import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final Function(int?) onSelected;

  const CategorySelector({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All" option that sets the category ID to null
        _buildCategoryChip(null, "All", selectedCategoryId == null, onSelected),
        ...categories.map((category) {
          // Ensure the ID is properly converted to int
          int categoryId =
              category['id'] is int
                  ? category['id']
                  : int.tryParse(category['id'].toString()) ?? 0;

          return _buildCategoryChip(
            categoryId,
            category['name'] ?? '',
            selectedCategoryId == categoryId,
            onSelected,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryChip(
    int? id,
    String name,
    bool isSelected,
    Function(int?) onSelected,
  ) {
    return FilterChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (_) => onSelected(id),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.orange : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.transparent,
        ),
      ),
    );
  }
}
