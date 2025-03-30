import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final Function(String?) onSelected;

  const CategorySelector({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategoryId == category['id'].toString();

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
            ),
          ),
          child: ListTile(
            title: Text(
              "${category['name']} (${category['count']})",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing:
                isSelected
                    ? const Icon(Icons.check, color: Colors.orange)
                    : null,
            onTap: () {
              if (isSelected) {
                onSelected(null); // Deselect
              } else {
                onSelected(category['id'].toString());
              }
            },
          ),
        );
      },
    );
  }
}
