import 'package:flutter/material.dart';

class SortOptions extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String selectedOption;
  final Function(String) onSelected;

  const SortOptions({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            options.map((option) {
              bool isSelected = selectedOption == option['id'];
              return GestureDetector(
                onTap: () => onSelected(option['id']),
                child: Container(
                  width:
                      (MediaQuery.of(context).size.width - 44) /
                      2, // Two columns
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option['name'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
