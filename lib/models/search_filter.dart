class SearchFilter {
  int? categoryId; // Using int? for category ID
  double minPrice;
  double maxPrice;
  String sortOption;
  bool onSale;
  bool featured;
  int layoutType; // Layout selection

  SearchFilter({
    this.categoryId,
    this.minPrice = 0.0,
    this.maxPrice = 5000.0,
    this.sortOption = 'popularity',
    this.onSale = false,
    this.featured = false,
    this.layoutType = 0, // Default to list view
  });

  // Create a copy with updated values
  SearchFilter copyWith({
    int? categoryId, // Using int? for consistency
    double? minPrice,
    double? maxPrice,
    String? sortOption,
    bool? onSale,
    bool? featured,
    int? layoutType,
  }) {
    return SearchFilter(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortOption: sortOption ?? this.sortOption,
      onSale: onSale ?? this.onSale,
      featured: featured ?? this.featured,
      layoutType: layoutType ?? this.layoutType,
    );
  }

  // Reset to default values
  void reset({double defaultMinPrice = 0.0, double defaultMaxPrice = 5000.0}) {
    categoryId = null;
    minPrice = defaultMinPrice;
    maxPrice = defaultMaxPrice;
    sortOption = 'popularity';
    onSale = false;
    featured = false;
    layoutType = 0;
  }

  // Check if any filter is applied
  bool get isFiltered {
    return categoryId != null ||
        minPrice > 0.0 ||
        maxPrice < 5000.0 ||
        sortOption != 'popularity' ||
        onSale ||
        featured ||
        layoutType != 0;
  }

  // Convert to query parameters for API
  Map<String, String> toQueryParameters() {
    Map<String, String> params = {};

    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }

    params['min_price'] = minPrice.toStringAsFixed(0);
    params['max_price'] = maxPrice.toStringAsFixed(0);

    if (sortOption.isNotEmpty) {
      if (sortOption == 'price-asc') {
        params['orderby'] = 'price';
        params['order'] = 'asc';
      } else if (sortOption == 'price-desc') {
        params['orderby'] = 'price';
        params['order'] = 'desc';
      } else {
        params['orderby'] = sortOption;
      }
    }

    if (onSale) {
      params['on_sale'] = 'true';
    }

    if (featured) {
      params['featured'] = 'true';
    }

    return params;
  }
}
