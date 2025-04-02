import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/screens/product_details_screen.dart';
import 'package:trueway_ecommerce/services/search_service.dart';
import 'package:trueway_ecommerce/widgets/ProductCard_Search.dart';
import 'package:trueway_ecommerce/widgets/ProductGridItem_search.dart';
import 'package:trueway_ecommerce/widgets/filters/filter_modal.dart';
import 'package:trueway_ecommerce/models/search_filter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Debounce for search
  Timer? _debounce;
  final int _debounceTime = 800; // milliseconds

  // Current search filters
  SearchFilter _currentFilter = SearchFilter();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      // Initialize the search service data
      await _searchService.initializeData();
      setState(() {});
    } catch (e) {
      print("Error initializing search data: $e");
    }
  }

  void _performSearch(String query) async {
    // Clear results if query is empty
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _searchService.searchProducts(
        query,
        _currentFilter,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error searching products: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showFilterDialog() async {
    final result = await showModalBottomSheet<SearchFilter?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => FilterModal(
            currentFilter: _currentFilter,
            categories: _searchService.categories,
            sortOptions: _searchService.sortOptions,
            minPrice: _searchService.minPrice,
            maxPrice: _searchService.maxPrice,
          ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });

      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Products"),
        actions: [
          // Add layout switcher button
          IconButton(
            icon: Icon(_getLayoutIcon(_currentFilter.layoutType)),
            onPressed: () {
              // Toggle between list and grid view
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  layoutType: _currentFilter.layoutType == 0 ? 1 : 0,
                );
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Search bar with filter button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults.clear();
                                    _hasSearched = false;
                                  });
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // Implement debounce to avoid excessive API calls
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(
                        Duration(milliseconds: _debounceTime),
                        () {
                          _performSearch(value);
                        },
                      );
                    },
                    onSubmitted: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _performSearch(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),

            // Results area
            Expanded(child: _buildResultsArea()),
          ],
        ),
      ),
    );
  }

  // Helper to get appropriate layout icon
  IconData _getLayoutIcon(int layoutType) {
    switch (layoutType) {
      case 0:
        return Icons.view_list;
      case 1:
        return Icons.grid_view;
      case 2:
        return Icons.crop_landscape;
      case 3:
        return Icons.view_stream;
      case 4:
        return Icons.segment;
      default:
        return Icons.view_list;
    }
  }

  Widget _buildResultsArea() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Initial state - no search performed yet
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Search for products",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // No results found
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No products found",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different search term or adjust filters",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Search results - dynamically adjust layout based on selection
    return _buildProductList();
  }

  Widget _buildProductList() {
    // Different layouts based on selection
    switch (_currentFilter.layoutType) {
      case 0: // Default list view
        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ProductCard_Search(
              product: _searchResults[index],
              onTap: () => _navigateToProductDetails(_searchResults[index]),
            );
          },
        );

      case 1: // Grid view (2 columns)
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ProductGridItem_search(
              product: _searchResults[index],
              onTap: () => _navigateToProductDetails(_searchResults[index]),
            );
          },
        );

      case 2: // Horizontal scroll list
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.7,
              margin: const EdgeInsets.only(right: 10),
              child: ProductCard_Search(
                product: _searchResults[index],
                onTap: () => _navigateToProductDetails(_searchResults[index]),
              ),
            );
          },
        );

      case 3: // Compact list
        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: SizedBox(
                width: 60,
                height: 60,
                child: _buildProductImage(_searchResults[index]),
              ),
              title: Text(
                _searchResults[index]['name'] ?? "No Name",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("₹${_searchResults[index]['price'] ?? '0'}"),
              onTap: () => _navigateToProductDetails(_searchResults[index]),
            );
          },
        );

      case 4: // Text only list
        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_searchResults[index]['name'] ?? "No Name"),
              subtitle: Text("₹${_searchResults[index]['price'] ?? '0'}"),
              onTap: () => _navigateToProductDetails(_searchResults[index]),
            );
          },
        );

      default:
        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ProductCard_Search(
              product: _searchResults[index],
              onTap: () => _navigateToProductDetails(_searchResults[index]),
            );
          },
        );
    }
  }

  // Building product image widget locally rather than relying on SearchService method
  Widget _buildProductImage(dynamic product) {
    // Check if product has images
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty &&
        product['images'][0]['src'] != null) {
      String imageUrl = product['images'][0]['src'];

      // Use CachedNetworkImage for better performance
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
      );
    } else {
      // Placeholder for products without images
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }

  void _navigateToProductDetails(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }
}
