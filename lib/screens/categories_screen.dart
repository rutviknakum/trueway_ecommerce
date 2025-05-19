import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/providers/wishlist_provider.dart';
import 'package:trueway_ecommerce/screens/SearchScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/services/product_service.dart';

class CategoriesScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoriesScreen({Key? key, this.category}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  // Basic state variables
  List categories = [];
  List originalProducts = []; // Store original unfiltered products
  List products = [];
  int selectedCategoryId = -1;
  String selectedCategoryName = "";
  bool isLoading = true;
  bool isLoadingProducts = false;
  bool _isMounted = true;
  late AnimationController _animationController;
  bool _viewingAllProducts = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  final int _perPage = 20;
  final ScrollController _scrollController = ScrollController();

  // Filter state variables
  String _selectedSortOption = 'Default';
  Map<String, dynamic> _activeFilters = {};
  RangeValues _priceRange = RangeValues(0, 10000);
  double _maxPrice = 10000;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);

    if (widget.category != null) {
      int categoryId;
      if (widget.category!['id'] is int) {
        categoryId = widget.category!['id'];
      } else if (widget.category!['id'] is String) {
        categoryId = int.tryParse(widget.category!['id'].toString()) ?? -1;
      } else {
        categoryId = -1;
      }

      final categoryName = widget.category!['name']?.toString() ?? "";
      _viewingAllProducts = true;
      fetchCategoriesAndInitialProducts(categoryId, categoryName);
    } else {
      fetchCategoriesAndProducts();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_viewingAllProducts && _hasMoreProducts && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  void fetchCategoriesAndInitialProducts(
    int categoryId,
    String categoryName,
  ) async {
    try {
      final productService = ProductService();
      final fetchedCategories = await productService.fetchCategories();

      if (!_isMounted) return;

      if (fetchedCategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            categories = fetchedCategories;
            selectedCategoryId = categoryId;
            selectedCategoryName = categoryName;
          });
        }

        await updateProductsForCategory(
          categoryId,
          categoryName,
          viewAll: true,
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching data: $e");
    }
  }

  void fetchCategoriesAndProducts() async {
    try {
      final productService = ProductService();
      final fetchedCategories = await productService.fetchCategories();

      if (!_isMounted) return;

      if (fetchedCategories.isNotEmpty) {
        int firstCategoryId;
        if (fetchedCategories[0]['id'] is int) {
          firstCategoryId = fetchedCategories[0]['id'];
        } else if (fetchedCategories[0]['id'] is String) {
          firstCategoryId =
              int.tryParse(fetchedCategories[0]['id'].toString()) ?? -1;
        } else {
          firstCategoryId = -1;
        }

        String firstCategoryName =
            fetchedCategories[0]['name']?.toString() ?? "";

        if (mounted) {
          setState(() {
            categories = fetchedCategories;
            selectedCategoryId = firstCategoryId;
            selectedCategoryName = firstCategoryName;
          });
        }

        await updateProductsForCategory(
          selectedCategoryId,
          selectedCategoryName,
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching data: $e");
    }
  }

  Future<void> updateProductsForCategory(
    int categoryId,
    String categoryName, {
    bool viewAll = false,
    bool preserveFilters = false,
  }) async {
    if (!mounted) return;

    setState(() {
      isLoadingProducts = true;
      products = [];
      originalProducts = [];
      _viewingAllProducts = viewAll;
      _currentPage = 1;
      _hasMoreProducts = true;

      // Only reset filters if not preserving them
      if (!preserveFilters) {
        _activeFilters = {};
        _selectedSortOption = 'Default';
        _priceRange = RangeValues(0, 10000);
      }
    });

    try {
      final productService = ProductService();
      final fetchedProducts = await productService.fetchProducts(
        categoryId: categoryId,
        page: viewAll ? _currentPage : 1,
        perPage: viewAll ? _perPage : _perPage,
      );

      if (mounted) {
        setState(() {
          originalProducts = List.from(fetchedProducts);
          products = fetchedProducts;
          selectedCategoryId = categoryId;
          selectedCategoryName = categoryName;
          isLoadingProducts = false;
          isLoading = false;

          if (viewAll) {
            _hasMoreProducts = fetchedProducts.length == _perPage;
          }

          // Calculate max price for price range filter
          _calculateMaxPrice();

          // If we have active filters, apply them to the new products
          if (preserveFilters &&
              (_activeFilters.isNotEmpty || _selectedSortOption != 'Default')) {
            _applyFilters();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
          isLoading = false;
        });
      }
      print("Error fetching products for category: $e");
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || _isLoadingMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final productService = ProductService();
      final moreProducts = await productService.fetchProducts(
        categoryId: selectedCategoryId,
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          if (moreProducts.isNotEmpty) {
            originalProducts.addAll(moreProducts); // Add to original products

            // Apply current filters to new products if needed
            if (_activeFilters.isNotEmpty || _selectedSortOption != 'Default') {
              List filteredMoreProducts = _filterProducts(moreProducts);
              products.addAll(filteredMoreProducts);
            } else {
              products.addAll(moreProducts);
            }
          }
          _isLoadingMore = false;
          _hasMoreProducts = moreProducts.length == _perPage;

          // Recalculate max price with new products
          _calculateMaxPrice();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
      print("Error loading more products: $e");
    }
  }

  // Filter helper methods
  void _calculateMaxPrice() {
    double maxPrice = 0;
    for (var product in originalProducts) {
      final priceStr = product['price']?.toString() ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;
      if (price > maxPrice) {
        maxPrice = price;
      }
    }

    setState(() {
      _maxPrice = maxPrice > 0 ? maxPrice : 10000;
      if (_priceRange.end > _maxPrice) {
        _priceRange = RangeValues(_priceRange.start, _maxPrice);
      }
    });
  }

  void _applyFilters() {
    setState(() {
      isLoadingProducts = true;
    });

    // Filter the products based on current filters
    List filteredProducts = _filterProducts(originalProducts);

    setState(() {
      products = filteredProducts;
      isLoadingProducts = false;
    });
  }

  List _filterProducts(List productsToFilter) {
    List filteredList = List.from(productsToFilter);

    // Apply price filter
    if (_activeFilters.containsKey('price')) {
      RangeValues priceRange = _activeFilters['price'];
      filteredList =
          filteredList.where((product) {
            final priceStr = product['price']?.toString() ?? '0';
            final price = double.tryParse(priceStr) ?? 0.0;
            return price >= priceRange.start && price <= priceRange.end;
          }).toList();
    }

    // Apply stock filter
    if (_activeFilters.containsKey('stock')) {
      bool inStockOnly = _activeFilters['stock'] == 'instock';
      filteredList =
          filteredList.where((product) {
            return product['in_stock'] == inStockOnly;
          }).toList();
    }

    // Apply rating filter
    if (_activeFilters.containsKey('rating')) {
      String minRating = _activeFilters['rating'];
      double ratingValue = double.tryParse(minRating) ?? 0.0;

      filteredList =
          filteredList.where((product) {
            final ratingStr = product['average_rating']?.toString() ?? '0';
            final rating = double.tryParse(ratingStr) ?? 0.0;
            return rating >= ratingValue;
          }).toList();
    }

    // Apply sorting
    if (_selectedSortOption != 'Default') {
      switch (_selectedSortOption) {
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

  void _resetFilters() {
    setState(() {
      _activeFilters = {};
      _selectedSortOption = 'Default';
      _priceRange = RangeValues(0, _maxPrice);
    });
    _applyFilters();
    print('Filters reset');
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Create a local copy of the price range for the sheet
    RangeValues localPriceRange = RangeValues(
      _priceRange.start,
      _priceRange.end,
    );
    Map<String, dynamic> localFilters = Map.from(_activeFilters);

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
                                        _maxPrice,
                                      );
                                      localFilters = {};
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
                                    // Update active filters with the local state from the modal
                                    setState(() {
                                      _activeFilters = Map.from(localFilters);
                                      _activeFilters['price'] = localPriceRange;
                                      _priceRange = localPriceRange;
                                    });
                                    _applyFilters();
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
                              max: _maxPrice,
                              divisions: 20,
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
                                  localFilters,
                                  (type, value, checked) {
                                    if (checked) {
                                      localFilters[type] = value;
                                    } else if (localFilters[type] == value) {
                                      localFilters.remove(type);
                                    }
                                  },
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  'Out of Stock',
                                  'stock',
                                  'outofstock',
                                  localFilters,
                                  (type, value, checked) {
                                    if (checked) {
                                      localFilters[type] = value;
                                    } else if (localFilters[type] == value) {
                                      localFilters.remove(type);
                                    }
                                  },
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
                                  localFilters,
                                  (type, value, checked) {
                                    if (checked) {
                                      localFilters[type] = value;
                                    } else if (localFilters[type] == value) {
                                      localFilters.remove(type);
                                    }
                                  },
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  '3+ Stars',
                                  'rating',
                                  '3',
                                  localFilters,
                                  (type, value, checked) {
                                    if (checked) {
                                      localFilters[type] = value;
                                    } else if (localFilters[type] == value) {
                                      localFilters.remove(type);
                                    }
                                  },
                                ),
                                _buildFilterChip(
                                  setModalState,
                                  '2+ Stars',
                                  'rating',
                                  '2',
                                  localFilters,
                                  (type, value, checked) {
                                    if (checked) {
                                      localFilters[type] = value;
                                    } else if (localFilters[type] == value) {
                                      localFilters.remove(type);
                                    }
                                  },
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
    Map<String, dynamic> filters,
    Function(String, String, bool) onSelected,
  ) {
    bool isSelected =
        filters.containsKey(filterType) && filters[filterType] == value;

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
          onSelected(filterType, value, selected);
        });
      },
    );
  }

  // Sort dropdown widget with fixed width to prevent overflow
  // Replace the _buildSortDropdown() method with this fixed version:
  Widget _buildSortDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 0,
      ), // Reduced padding
      constraints: BoxConstraints(maxWidth: 120), // Even smaller max width
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSortOption,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[700],
            size: 14,
          ), // Smaller dropdown icon
          style: TextStyle(
            fontSize: 11, // Smaller font
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          isExpanded: true,
          menuMaxHeight: 300, // Limit dropdown menu height
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSortOption = newValue;
              });
              _applyFilters();
            }
          },
          items: <String>[
            'Default',
            'Price: Low to High',
            'Price: High to Low',
            'Newest First',
            'Popularity',
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Fixed filter bar with smaller components to prevent overflow
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ), // Further reduced horizontal padding
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Sort Dropdown with Flexible to prevent overflow
          Flexible(
            flex: 3, // Give sort dropdown more space
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 12,
                  color: Colors.grey[700],
                ), // Even smaller icon
                SizedBox(width: 2),
                Text(
                  'Sort:',
                  style: TextStyle(
                    fontSize: 11, // Smaller text
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 2),
                Flexible(child: _buildSortDropdown()),
              ],
            ),
          ),

          SizedBox(width: 2), // Minimal spacing
          // Filter Button
          Flexible(
            flex: 2, // Filter button takes less space
            child: InkWell(
              onTap: () => _showFilterBottomSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ), // Further reduced padding
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                  color:
                      _activeFilters.isNotEmpty
                          ? Colors.teal[50]
                          : Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 12, // Smaller icon
                      color:
                          _activeFilters.isNotEmpty
                              ? Colors.teal[700]
                              : Colors.grey[700],
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 11, // Smaller text
                        fontWeight: FontWeight.w500,
                        color:
                            _activeFilters.isNotEmpty
                                ? Colors.teal[700]
                                : Colors.grey[700],
                      ),
                    ),
                    if (_activeFilters.isNotEmpty) ...[
                      SizedBox(width: 2),
                      Container(
                        padding: EdgeInsets.all(2), // Smaller padding
                        decoration: BoxDecoration(
                          color: Colors.teal[700],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _activeFilters.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8, // Smaller text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (_activeFilters.isNotEmpty ||
              _selectedSortOption != 'Default') ...[
            SizedBox(width: 2), // Smaller gap
            Flexible(
              flex: 1, // Clear button takes least space
              child: InkWell(
                onTap: _resetFilters,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ), // Minimum padding
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.red[50],
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 11, // Smaller text
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, dynamic product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    int productId;
    if (product["id"] is int) {
      productId = product["id"];
    } else if (product["id"] is String) {
      productId = int.tryParse(product["id"].toString()) ?? 0;
    } else {
      productId = 0;
    }

    final productName = product["name"]?.toString() ?? 'No Name';
    final String priceStr = product['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'];
    }

    final cartItem = CartItem(
      id: productId,
      name: productName,
      image: imageUrl,
      price: price,
      quantity: 1,
      variationId: 0,
      imageUrl: null,
    );

    cartProvider.addToCart(cartItem);
    _animationController.reset();
    _animationController.forward();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "$productName added to cart",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => CartScreen()));
              },
              child: Text(
                "VIEW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.items.length;

    return Scaffold(
      appBar: AppBar(
        elevation: Theme.of(context).appBarTheme.elevation,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          _viewingAllProducts ? selectedCategoryName : "Category",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        leading:
            _viewingAllProducts
                ? IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _viewingAllProducts = false;
                    });
                    updateProductsForCategory(
                      selectedCategoryId,
                      selectedCategoryName,
                    );
                  },
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _animationController.value * 0.3,
                      child: Icon(
                        Icons.shopping_cart,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        size: 28,
                      ),
                    );
                  },
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : _viewingAllProducts
              ? _buildAllProductsView()
              : _buildCategoriesView(),
    );
  }

  Widget _buildCategoriesView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Categories list with classic styling
        Container(
          width: 100,
          color: Colors.transparent,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              int categoryId;
              if (category['id'] is int) {
                categoryId = category['id'];
              } else if (category['id'] is String) {
                categoryId = int.tryParse(category['id'].toString()) ?? -1;
              } else {
                categoryId = -1;
              }

              final isSelected = selectedCategoryId == categoryId;

              String imageUrl = '';
              if (category['image'] != null) {
                if (category['image'] is Map &&
                    category['image']['src'] != null) {
                  imageUrl = category['image']['src'].toString();
                } else if (category['image'] is String) {
                  imageUrl = category['image'];
                }
              }

              return GestureDetector(
                onTap: () {
                  String categoryName = '';
                  if (category['name'] != null) {
                    categoryName = category['name'].toString();
                  }

                  updateProductsForCategory(categoryId, categoryName);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(
                        color:
                            isSelected ? Colors.teal[600]! : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Category Image with classic frame
                      Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.category,
                                        size: 24,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.category,
                                  size: 24,
                                  color: Colors.grey[400],
                                ),
                      ),
                      SizedBox(height: 8),
                      // Category Name with classic typography
                      Text(
                        category['name']?.toString() ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? Colors.teal[700] : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Right side: Products Grid with classic styling
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Add filter bar directly (removed category header and View All button)
                if (!isLoadingProducts) _buildFilterBar(),

                // Products Grid View with classic styling
                Expanded(
                  child:
                      isLoadingProducts
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.teal[600]!,
                              ),
                            ),
                          )
                          : products.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try selecting a different category or adjusting your filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          : GridView.builder(
                            padding: EdgeInsets.all(10),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.56,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildClassicProductItem(
                                context,
                                products[index],
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllProductsView() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Add filter bar at the top
          if (!isLoadingProducts) _buildFilterBar(),

          // Products List
          Expanded(
            child:
                isLoadingProducts
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.teal[600]!,
                        ),
                      ),
                    )
                    : products.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.6, // Adjusted for more compact cards
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12, // Balanced spacing for visual hierarchy
                      ),
                      itemCount:
                          _isLoadingMore
                              ? products.length + 1
                              : products.length,
                      itemBuilder: (context, index) {
                        if (index == products.length && _isLoadingMore) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.teal[600]!,
                                ),
                                strokeWidth: 2.0,
                              ),
                            ),
                          );
                        }
                        return _buildClassicProductItem(
                          context,
                          products[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicProductItem(BuildContext context, dynamic product) {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    int productId;
    if (product["id"] is int) {
      productId = product["id"];
    } else if (product["id"] is String) {
      productId = int.tryParse(product["id"].toString()) ?? 0;
    } else {
      productId = 0;
    }

    final productName = product["name"]?.toString() ?? 'No Name';
    final isWishlisted = wishlistProvider.isWishlisted(productId);

    final String priceStr = product['price']?.toString() ?? '0';
    final String regularPriceStr = product['regular_price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;
    final regularPrice = double.tryParse(regularPriceStr) ?? 0.0;

    final hasDiscount = regularPrice > 0 && regularPrice != price;
    final discountPercentage = hasDiscount ? ((regularPrice - price) / regularPrice) * 100 : 0;

    String imageUrl = '';
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0] != null &&
        product['images'][0]['src'] != null) {
      imageUrl = product['images'][0]['src'].toString();
    }

    final bool inStock = product['in_stock'] ?? true;
    final Color primaryColor = Colors.teal[700]!;

    // Enhanced modern product card with smooth shadows and depth
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with improved styling
              Stack(
                children: [
                  // Product Image with fixed aspect ratio for consistency
                  AspectRatio(
                    aspectRatio: 1.0, // Square aspect ratio for consistency
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'product_$productId',
                        child: imageUrl.isNotEmpty
                            ? ClipRRect(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  // Add placeholders to reduce layout shift
                                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                    if (frame == null) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    }
                                    return child;
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 28,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 28,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Improved discount badge with modern design
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          "-${discountPercentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    
                  // Wishlist button in corner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: IconButton(
                        constraints: BoxConstraints(
                          minHeight: 32,
                          minWidth: 32,
                        ),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.red : Colors.grey[600],
                        ),
                        onPressed: () {
                          if (isWishlisted) {
                            wishlistProvider.removeFromWishlist(productId);
                          } else {
                            wishlistProvider.addToWishlist(product);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Product Details section with flexible layout to prevent overflow
              Padding(
                padding: EdgeInsets.all(8), // Reduced padding to save space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Use minimum space needed
                  children: [
                    // Product Name with more compact design
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: 13, // Slightly smaller font
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4), // Reduced spacing

                    // Price Display with improved visual hierarchy
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "₹${price.toInt()}",
                          style: TextStyle(
                            fontSize: 15, // Slightly smaller font
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (hasDiscount) ...
                        [
                          SizedBox(width: 4), // Reduced spacing
                          Text(
                            "₹${regularPrice.toInt()}",
                            style: TextStyle(
                              fontSize: 11, // Slightly smaller font
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6), // Fixed height spacer instead of Spacer

                    // Stock status and Add to Cart row with improved UI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stock Status chip with better styling
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: inStock ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inStock ? "In stock" : "Out of stock",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: inStock ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),

                        // Add to Cart Button with improved styling
                        GestureDetector(
                          onTap: inStock ? () => _addToCart(context, product) : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: inStock ? primaryColor : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: inStock
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Add",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}
