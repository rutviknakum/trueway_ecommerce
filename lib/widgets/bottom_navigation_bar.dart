import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/Navigation_Provider.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final navigationProvider = Provider.of<NavigationProvider>(context);

    // Determine colors based on theme
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final backgroundColor = isDarkMode ? colorScheme.surface : Colors.white;
    final shadowColor = Colors.black.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                navigationProvider.navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = navigationProvider.currentIndex == index;

                  return Expanded(
                    child: NavItem(
                      item: item,
                      isSelected: isSelected,
                      primaryColor: primaryColor,
                      unselectedColor: unselectedColor,
                      onTap: () => navigationProvider.setCurrentIndex(index),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final Color primaryColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const NavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.unselectedColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item['activeIcon'] : item['inactiveIcon'],
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 24,
                ),
              ),
              // Badge indicator for items with counts
              if (item['badge'] != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Badge(count: item['badge']),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final int count;

  const Badge({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
