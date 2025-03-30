import 'package:flutter/material.dart';

class LayoutSelector extends StatelessWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final Function(int) onSelected;

  const LayoutSelector({
    Key? key,
    required this.selectedIndex,
    required this.icons,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          icons.length,
          (index) => GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    selectedIndex == index
                        ? const Color(0xFFFAE9CC) // Light orange for selected
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      selectedIndex == index
                          ? Colors.orange
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                icons[index],
                color:
                    selectedIndex == index ? Colors.orange : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
