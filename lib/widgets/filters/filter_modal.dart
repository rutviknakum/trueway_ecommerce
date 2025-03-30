import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/models/search_filter.dart';
import 'package:trueway_ecommerce/widgets/filters/filter_section.dart';
import 'package:trueway_ecommerce/widgets/filters/layout_selector.dart';
import 'package:trueway_ecommerce/widgets/filters/price_range_slider.dart';
import 'package:trueway_ecommerce/widgets/filters/sort_options.dart';
import 'package:trueway_ecommerce/widgets/filters/category_selector.dart';

class FilterModal extends StatefulWidget {
  final SearchFilter currentFilter;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> sortOptions;
  final double minPrice;
  final double maxPrice;

  const FilterModal({
    Key? key,
    required this.currentFilter,
    required this.categories,
    required this.sortOptions,
    required this.minPrice,
    required this.maxPrice,
  }) : super(key: key);

  @override
  _FilterModalState createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late SearchFilter _filter;
  late RangeValues _priceRange;

  final List<IconData> _layoutIcons = [
    Icons.grid_view,
    Icons.grid_3x3,
    Icons.crop_landscape,
    Icons.view_stream,
    Icons.segment,
  ];

  @override
  void initState() {
    super.initState();
    // Create a copy of the current filter to work with
    _filter = SearchFilter(
      categoryId: widget.currentFilter.categoryId,
      minPrice: widget.currentFilter.minPrice,
      maxPrice: widget.currentFilter.maxPrice,
      sortOption: widget.currentFilter.sortOption,
      layoutType: widget.currentFilter.layoutType,
    );

    _priceRange = RangeValues(_filter.minPrice, _filter.maxPrice);
  }

  // Reset all filters to default values
  void _clearFilters() {
    setState(() {
      _filter.reset(
        defaultMinPrice: widget.minPrice,
        defaultMaxPrice: widget.maxPrice,
      );
      _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Pill indicator at top
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layouts Section
                  FilterSection(
                    title: "Layouts",
                    child: LayoutSelector(
                      selectedIndex: _filter.layoutType,
                      icons: _layoutIcons,
                      onSelected: (index) {
                        setState(() {
                          _filter = _filter.copyWith(layoutType: index);
                        });
                      },
                    ),
                  ),

                  // Sort by Section
                  FilterSection(
                    title: "Sort by",
                    child: SortOptions(
                      options: widget.sortOptions,
                      selectedOption: _filter.sortOption,
                      onSelected: (option) {
                        setState(() {
                          _filter = _filter.copyWith(sortOption: option);
                        });
                      },
                    ),
                  ),

                  // Price Section
                  FilterSection(
                    title: "Price",
                    child: PriceRangeSlider(
                      values: _priceRange,
                      min: widget.minPrice,
                      max: widget.maxPrice,
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                          _filter = _filter.copyWith(
                            minPrice: values.start,
                            maxPrice: values.end,
                          );
                        });
                      },
                    ),
                  ),

                  // Category Section
                  if (widget.categories.isNotEmpty)
                    FilterSection(
                      title: "Category",
                      child: CategorySelector(
                        categories: widget.categories,
                        selectedCategoryId: _filter.categoryId,
                        onSelected: (categoryId) {
                          setState(() {
                            _filter = _filter.copyWith(categoryId: categoryId);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Clear Filters Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Clear Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _filter);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Apply Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
