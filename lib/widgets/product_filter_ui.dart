import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/utils/product_filter_helper.dart';

class ProductFilterBar extends StatelessWidget {
  final ProductFilterHelper filterHelper;
  final Function() onFilterApplied;
  final Function() onFilterReset;

  const ProductFilterBar({
    Key? key,
    required this.filterHelper,
    required this.onFilterApplied,
    required this.onFilterReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Sort Dropdown
          Row(
            children: [
              Icon(Icons.sort, size: 16, color: Colors.grey[700]),
              SizedBox(width: 4),
              Text(
                'Sort:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 4),
              _buildSortDropdown(context),
            ],
          ),

          Spacer(),

          // Filter Button
          InkWell(
            onTap: () => _showFilterBottomSheet(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
                color:
                    filterHelper.activeFilters.isNotEmpty
                        ? Colors.teal[50]
                        : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color:
                        filterHelper.activeFilters.isNotEmpty
                            ? Colors.teal[700]
                            : Colors.grey[700],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          filterHelper.activeFilters.isNotEmpty
                              ? Colors.teal[700]
                              : Colors.grey[700],
                    ),
                  ),
                  if (filterHelper.activeFilters.isNotEmpty) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.teal[700],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        filterHelper.activeFilters.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (filterHelper.hasActiveFilters) ...[
            SizedBox(width: 8),
            InkWell(
              onTap: onFilterReset,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red[50],
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterHelper.selectedSortOption,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              filterHelper.selectedSortOption = newValue;
              onFilterApplied();
            }
          },
          items:
              <String>[
                'Default',
                'Price: Low to High',
                'Price: High to Low',
                'Newest First',
                'Popularity',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Make a local copy of price range to use in the sheet
    RangeValues localPriceRange = filterHelper.priceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Filter Header
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter Products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      localPriceRange = RangeValues(
                                        0,
                                        filterHelper.maxPrice,
                                      );
                                    });
                                  },
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(color: Colors.red[600]),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // Update active filters with current modal state
                                    filterHelper.activeFilters['price'] =
                                        localPriceRange;
                                    onFilterApplied();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Text('Apply'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Filter Content
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.all(16),
                          children: [
                            // Price Range Filter
                            Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${localPriceRange.start.toInt()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${localPriceRange.end.toInt()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: localPriceRange,
                              min: 0,
                              max: filterHelper.maxPrice,
                              divisions: 100,
                              activeColor: Colors.teal[600],
                              inactiveColor: Colors.grey[300],
                              labels: RangeLabels(
                                '₹${localPriceRange.start.toInt()}',
                                '₹${localPriceRange.end.toInt()}',
                              ),
                              onChanged: (RangeValues values) {
                                setModalState(() {
                                  localPriceRange = values;
                                });
                              },
                            ),

                            Divider(height: 24),

                            // Stock status filter
                            Text(
                              'Availability',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  setModalState,
                                  'In Stock',
                                  'stock',
                                  'instock',
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  'Out of Stock',
                                  'stock',
                                  'outofstock',
                                ),
                              ],
                            ),

                            Divider(height: 24),

                            // Rating filter
                            Text(
                              'Product Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  setModalState,
                                  '4+ Stars',
                                  'rating',
                                  '4',
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  '3+ Stars',
                                  'rating',
                                  '3',
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  '2+ Stars',
                                  'rating',
                                  '2',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildFilterChip(
    StateSetter setState,
    String label,
    String filterType,
    String value,
  ) {
    // Check if this filter is active
    bool isSelected = filterHelper.isFilterActive(filterType, value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.teal[100],
      checkmarkColor: Colors.teal[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.teal[700] : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: isSelected ? Colors.teal[600]! : Colors.grey[400]!,
          width: 1,
        ),
      ),
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            filterHelper.updateFilter(filterType, value);
          } else {
            filterHelper.updateFilter(filterType, value, remove: true);
          }
        });
      },
    );
  }
}
