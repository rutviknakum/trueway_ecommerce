import 'package:flutter/material.dart';

class ProductFilterHelper {
  // Filter state
  Map<String, dynamic> activeFilters = {};
  String selectedSortOption = 'Default';
  RangeValues priceRange = RangeValues(0, 10000);
  double maxPrice = 10000;

  // Initialize with default values or existing values
  ProductFilterHelper({
    this.activeFilters = const {},
    this.selectedSortOption = 'Default',
    RangeValues? initialPriceRange,
    double? initialMaxPrice,
  }) {
    if (initialMaxPrice != null) {
      maxPrice = initialMaxPrice;
    }

    if (initialPriceRange != null) {
      priceRange = initialPriceRange;
    } else {
      priceRange = RangeValues(0, maxPrice);
    }
  }

  // Reset all filters
  void resetFilters() {
    activeFilters = {};
    selectedSortOption = 'Default';
    priceRange = RangeValues(0, maxPrice);
  }

  // Calculate max price from product list
  void calculateMaxPrice(List products) {
    double maxPriceValue = 0;
    for (var product in products) {
      final priceStr = product['price']?.toString() ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;
      if (price > maxPriceValue) {
        maxPriceValue = price;
      }
    }

    maxPrice = maxPriceValue > 0 ? maxPriceValue : 10000;
    if (priceRange.end > maxPrice) {
      priceRange = RangeValues(priceRange.start, maxPrice);
    }
  }

  // Main filter method
  List filterProducts(List products) {
    List filteredList = List.from(products);

    // Apply price filter
    if (activeFilters.containsKey('price')) {
      RangeValues priceRange = activeFilters['price'];
      filteredList =
          filteredList.where((product) {
            final priceStr = product['price']?.toString() ?? '0';
            final price = double.tryParse(priceStr) ?? 0.0;
            return price >= priceRange.start && price <= priceRange.end;
          }).toList();
    }

    // Apply stock filter
    if (activeFilters.containsKey('stock')) {
      bool inStockOnly = activeFilters['stock'] == 'instock';
      filteredList =
          filteredList.where((product) {
            return product['in_stock'] == inStockOnly;
          }).toList();
    }

    // Apply rating filter
    if (activeFilters.containsKey('rating')) {
      String minRating = activeFilters['rating'];
      double ratingValue = double.tryParse(minRating) ?? 0.0;

      filteredList =
          filteredList.where((product) {
            final ratingStr = product['average_rating']?.toString() ?? '0';
            final rating = double.tryParse(ratingStr) ?? 0.0;
            return rating >= ratingValue;
          }).toList();
    }

    // Apply attributes filter
    if (activeFilters.containsKey('attributes') &&
        activeFilters['attributes'].isNotEmpty) {
      Map<String, List<String>> attributeFilters = activeFilters['attributes'];

      filteredList =
          filteredList.where((product) {
            if (product['attributes'] == null) return false;

            bool matches = true;
            attributeFilters.forEach((attributeName, selectedValues) {
              if (selectedValues.isEmpty) return; // Skip if no values selected

              var productAttribute = product['attributes'].firstWhere(
                (attr) => attr['name'] == attributeName,
                orElse: () => null,
              );

              if (productAttribute != null) {
                bool attributeMatch = false;
                for (String value in selectedValues) {
                  if (productAttribute['option'].toString() == value) {
                    attributeMatch = true;
                    break;
                  }
                }
                if (!attributeMatch) {
                  matches = false;
                }
              }
            });

            return matches;
          }).toList();
    }

    // Apply sorting
    if (selectedSortOption != 'Default') {
      switch (selectedSortOption) {
        case 'Price: Low to High':
          filteredList.sort((a, b) {
            final priceA =
                double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
            final priceB =
                double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
            return priceA.compareTo(priceB);
          });
          break;
        case 'Price: High to Low':
          filteredList.sort((a, b) {
            final priceA =
                double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
            final priceB =
                double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
            return priceB.compareTo(priceA);
          });
          break;
        case 'Newest First':
          filteredList.sort((a, b) {
            final dateA =
                a['date_created'] != null
                    ? DateTime.parse(a['date_created'].toString())
                    : DateTime(2000);
            final dateB =
                b['date_created'] != null
                    ? DateTime.parse(b['date_created'].toString())
                    : DateTime(2000);
            return dateB.compareTo(dateA);
          });
          break;
        case 'Popularity':
          filteredList.sort((a, b) {
            final ratingA =
                a['average_rating'] != null
                    ? double.tryParse(a['average_rating'].toString()) ?? 0.0
                    : 0.0;
            final ratingB =
                b['average_rating'] != null
                    ? double.tryParse(b['average_rating'].toString()) ?? 0.0
                    : 0.0;
            return ratingB.compareTo(ratingA);
          });
          break;
      }
    }

    return filteredList;
  }

  // Helper method to check if a specific filter is active
  bool isFilterActive(String filterType, String value) {
    if (activeFilters.containsKey(filterType)) {
      return activeFilters[filterType] == value;
    }
    return false;
  }

  // Helper method to check if an attribute filter is active
  bool isAttributeFilterActive(String attributeName, String value) {
    if (activeFilters.containsKey('attributes') &&
        activeFilters['attributes'] is Map &&
        activeFilters['attributes'].containsKey(attributeName)) {
      return (activeFilters['attributes'][attributeName] as List).contains(
        value,
      );
    }
    return false;
  }

  // Update a single filter
  void updateFilter(String filterType, dynamic value, {bool remove = false}) {
    if (remove) {
      if (activeFilters.containsKey(filterType)) {
        activeFilters.remove(filterType);
      }
    } else {
      activeFilters[filterType] = value;
    }
  }

  // Update an attribute filter
  void updateAttributeFilter(
    String attributeName,
    String value, {
    bool remove = false,
  }) {
    // Initialize attributes map if not exists
    if (!activeFilters.containsKey('attributes')) {
      activeFilters['attributes'] = <String, List<String>>{};
    }

    // Initialize attribute list if not exists
    if (!activeFilters['attributes'].containsKey(attributeName)) {
      activeFilters['attributes'][attributeName] = <String>[];
    }

    if (remove) {
      // Remove value from attribute list
      activeFilters['attributes'][attributeName].remove(value);

      // Clean up empty lists
      if (activeFilters['attributes'][attributeName].isEmpty) {
        activeFilters['attributes'].remove(attributeName);

        if (activeFilters['attributes'].isEmpty) {
          activeFilters.remove('attributes');
        }
      }
    } else {
      // Add value to attribute list
      activeFilters['attributes'][attributeName].add(value);
    }
  }

  // Check if any filters are active
  bool get hasActiveFilters =>
      activeFilters.isNotEmpty || selectedSortOption != 'Default';

  // Get the count of active filter categories
  int get activeFilterCount =>
      activeFilters.length + (selectedSortOption != 'Default' ? 1 : 0);
}
