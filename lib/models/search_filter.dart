class SearchFilter {
  String? categoryId;
  double minPrice;
  double maxPrice;
  String sortOption;
  int layoutType;

  SearchFilter({
    this.categoryId,
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.sortOption = 'menu_order',
    this.layoutType = 0,
  });

  // Create a copy with updated values
  SearchFilter copyWith({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortOption,
    int? layoutType,
  }) {
    return SearchFilter(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortOption: sortOption ?? this.sortOption,
      layoutType: layoutType ?? this.layoutType,
    );
  }

  // Reset filter to default values
  void reset({double defaultMinPrice = 0, double defaultMaxPrice = 5000}) {
    categoryId = null;
    minPrice = defaultMinPrice;
    maxPrice = defaultMaxPrice;
    sortOption = 'menu_order';
    layoutType = 0;
  }
}
