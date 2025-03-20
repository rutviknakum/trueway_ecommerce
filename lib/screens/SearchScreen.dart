import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_screen.dart';

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
        setState(() {
          _searchResults = products;
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Filter Options",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Price Filter
                  Text("Price Range (INR)", style: TextStyle(fontSize: 16)),
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

                  // Category Dropdown (Now Dynamic)
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: Text("Select Category"),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items:
                        _categories.map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category["id"].toString(),
                            child: Text(category["name"]),
                          );
                        }).toList(),
                  ),

                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _searchProducts(_searchController.text); // Apply filters
                    },
                    child: Text("Apply Filters"),
                  ),
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
            SizedBox(height: 10),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(child: Text("No results found"))
                : Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var product = _searchResults[index];
                      return _buildProductCard(product);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map product) {
    String imageUrl =
        (product["images"] != null && product["images"].isNotEmpty)
            ? product["images"][0]["src"]
            : "https://via.placeholder.com/150";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductDetailsScreen(
                  product: product as Map<String, dynamic>,
                ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          leading: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          title: Text(product["name"] ?? "No Name"),
          subtitle: Text("₹${product["price"] ?? "N/A"}"),
        ),
      ),
    );
  }
}
