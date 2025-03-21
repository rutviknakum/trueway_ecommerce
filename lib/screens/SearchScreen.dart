import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trueway_ecommerce/screens/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  // Filters
  String? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 100000;
  List<Map<String, dynamic>> _categories = [];

  static const String baseUrl = "https://map.uminber.in/wp-json/wc/v3/products";
  static const String categoryUrl =
      "https://map.uminber.in/wp-json/wc/v3/products/categories";
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when screen loads
  }

  /// Fetches product categories from WooCommerce API
  void _fetchCategories() async {
    final url = Uri.parse(
      "$categoryUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> categories = json.decode(response.body);
        setState(() {
          _categories =
              categories
                  .map((cat) => {"id": cat["id"], "name": cat["name"]})
                  .toList();
        });
      } else {
        print("Failed to fetch categories");
      }
    } catch (e) {
      print("Category fetch error: $e");
    }
  }

  /// Searches products based on the query and selected filters
  // void _searchProducts(String query) async {
  //   if (query.isEmpty) {
  //     setState(() {
  //       _searchResults.clear();
  //     });
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   final url = Uri.parse(
  //     "$baseUrl?search=$query"
  //     "&consumer_key=$consumerKey&consumer_secret=$consumerSecret"
  //     "${_selectedCategory != null ? '&category=$_selectedCategory' : ''}"
  //     "&min_price=${_minPrice.toInt()}"
  //     "&max_price=${_maxPrice.toInt()}",
  //   );

  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       List<dynamic> products = json.decode(response.body);
  //       setState(() {
  //         _searchResults = products;
  //       });
  //     } else {
  //       throw Exception("Failed to fetch search results");
  //     }
  //   } catch (e) {
  //     print("Search error: $e");
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  void _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      "$baseUrl?search=$query"
      "&consumer_key=$consumerKey&consumer_secret=$consumerSecret"
      "${_selectedCategory != null ? '&category=$_selectedCategory' : ''}"
      "&min_price=${_minPrice.toInt()}"
      "&max_price=${_maxPrice.toInt()}",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);

        // Filtering out products that don’t match the search query correctly
        List<dynamic> filteredProducts =
            products.where((product) {
              String name = (product['name'] ?? "").toString().toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

        // Ensuring all Boolean fields are safely converted to avoid type errors
        for (var product in filteredProducts) {
          product['on_sale'] =
              product['on_sale'] ?? false; // Handle null safely
        }

        setState(() {
          _searchResults = filteredProducts;
        });
      } else {
        throw Exception("Failed to fetch search results");
      }
    } catch (e) {
      print("Search error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Shows the filter modal bottom sheet
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      "Filter Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Card for Filters
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Range
                          Text(
                            "Price Range (INR)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 100000,
                            divisions: 20,
                            labels: RangeLabels(
                              "${_minPrice.toInt()} INR",
                              "${_maxPrice.toInt()} INR",
                            ),
                            onChanged: (RangeValues values) {
                              setState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),

                          SizedBox(height: 12),

                          // Category Dropdown
                          Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            hint: Text("Select Category"),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            items:
                                _categories.map<DropdownMenuItem<String>>((
                                  category,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: category["id"].toString(),
                                    child: Text(category["name"]),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Buttons Row
                  Row(
                    children: [
                      // Clear Filters Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _minPrice = 0;
                              _maxPrice = 100000;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.clear, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Clear Filters",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      // Apply Filters Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _searchProducts(_searchController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Apply Filters",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Products")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _searchProducts(value);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
              ],
            ),
            if (_isLoading)
              CircularProgressIndicator()
            else
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: _searchResults.length,
              //     itemBuilder: (context, index) {
              //       var product = _searchResults[index];
              //       return ListTile(
              //         title: Text(product['name']),
              //         subtitle: Text(
              //           'Price: ${product['price']} INR',
              //         ), // Display price
              //         // Add more details as needed
              //       );
              //     },
              //   ),
              // )
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    var product = _searchResults[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading:
                              product['images'] != null &&
                                      product['images'].isNotEmpty
                                  ? Image.network(
                                    product['images'][0]['src'], // Correct WooCommerce image path
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(Icons.image_not_supported, size: 60),
                          title: Text(
                            product['name'] ?? "No Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ((product['regular_price'] != null &&
                                      product['price'] != null &&
                                      product['regular_price'] !=
                                          product['price'])
                                  ? Row(
                                    children: [
                                      Text(
                                        "₹${product['regular_price'] ?? '0'}",
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "₹${product['price'] ?? '0'}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    "₹${product['price'] ?? '0'}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
