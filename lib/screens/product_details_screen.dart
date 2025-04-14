import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailsScreen({required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  int _selectedImageIndex = 0;
  TabController? _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Initialize the tab controller
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Safely dispose the tab controller
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract product data with robust error handling
    List<dynamic> images = widget.product["images"] ?? [];
    String productName = widget.product["name"] ?? "Unknown Product";

    // Price handling with better error prevention
    String productPriceStr = widget.product["price"]?.toString() ?? "0.0";
    double currentPrice = 0.0;
    try {
      if (productPriceStr.isNotEmpty) {
        String cleanedPrice = productPriceStr.replaceAll(RegExp(r'[^\d.]'), '');
        if (cleanedPrice.isNotEmpty) {
          currentPrice = double.parse(cleanedPrice);
        }
      }
    } catch (e) {
      currentPrice = 0.0;
    }

    // Regular price handling with better error prevention
    String regularPriceStr =
        widget.product["regular_price"]?.toString() ?? productPriceStr;
    double regularPrice = 0.0;
    try {
      if (regularPriceStr.isNotEmpty) {
        String cleanedRegPrice = regularPriceStr.replaceAll(
          RegExp(r'[^\d.]'),
          '',
        );
        if (cleanedRegPrice.isNotEmpty) {
          regularPrice = double.parse(cleanedRegPrice);
        }
      }
    } catch (e) {
      regularPrice = currentPrice;
    }

    bool hasDiscount = regularPrice > currentPrice && regularPrice > 0;
    int discountPercentage = 0;
    if (hasDiscount && regularPrice > 0) {
      discountPercentage =
          ((regularPrice - currentPrice) / regularPrice * 100).round();
    }

    String stockStatus =
        widget.product["stock_status"] == "instock"
            ? "In Stock"
            : "Out of Stock";

    // Properly extract and clean description
    String description = "";
    if (widget.product["description"] != null) {
      description =
          widget.product["description"]
              .toString()
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
      if (description.isEmpty) {
        description = "No description available for this product.";
      }
    } else {
      description = "No description available for this product.";
    }

    // Safely handle weight with error prevention
    String weight = "1";
    double weightValue = 1.0;
    try {
      weight = widget.product["weight"]?.toString() ?? "1";
      String cleanedWeight = weight.replaceAll(RegExp(r'[^\d.]'), '');
      if (cleanedWeight.isNotEmpty) {
        weightValue = double.parse(cleanedWeight);
      }
    } catch (e) {
      weight = "1";
      weightValue = 1.0;
    }

    String unit = "kg";

    // Rating handling with error prevention
    double ratings = 4.5;
    try {
      String ratingStr = widget.product["average_rating"]?.toString() ?? "4.5";
      if (ratingStr.isNotEmpty) {
        ratings = double.parse(ratingStr);
      }
    } catch (e) {
      ratings = 4.5;
    }

    int reviewCount = widget.product["rating_count"] ?? 250;
    String brand = widget.product["brand"] ?? "Aashirvaad";

    // Extract category information - no longer needed for similar products

    // Function to create a CartItem object from the current product
    CartItem createCartItemFromProduct() {
      String selectedImageUrl = "";
      if (images.isNotEmpty && _selectedImageIndex < images.length) {
        selectedImageUrl = images[_selectedImageIndex]["src"] ?? "";
      }

      return CartItem(
        id:
            widget.product["id"] is int
                ? widget.product["id"]
                : int.tryParse(widget.product["id"].toString()) ?? 0,
        name: productName,
        image: selectedImageUrl,
        price: currentPrice,
        quantity: quantity,
        imageUrl: null,
      );
    }

    // Function to add the current product to cart
    void addProductToCart() {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final cartItem = createCartItemFromProduct();
      cart.addToCart(cartItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$productName added to cart!"),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Build the main product image carousel
    Widget buildMainImage() {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CarouselSlider(
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _selectedImageIndex = index;
              });
            },
          ),
          items:
              images.isNotEmpty
                  ? images.map((img) {
                    return CachedNetworkImage(
                      imageUrl: img["src"] ?? "https://via.placeholder.com/300",
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    );
                  }).toList()
                  : [
                    Image.network(
                      "https://via.placeholder.com/300",
                      fit: BoxFit.contain,
                    ),
                  ],
        ),
      );
    }

    // Build indicator dots for the carousel
    Widget buildIndicators() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            images.asMap().entries.map((entry) {
              return Container(
                width: _selectedImageIndex == entry.key ? 12.0 : 8.0,
                height: 8.0,
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color:
                      _selectedImageIndex == entry.key
                          ? Colors.green
                          : Colors.grey.shade300,
                ),
              );
            }).toList(),
      );
    }

    // Build rating widget
    Widget buildRating() {
      return Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.green.shade700),
                SizedBox(width: 4),
                Text(
                  "11 MINS",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < ratings.floor()
                        ? Icons.star
                        : (index == ratings.floor() && ratings % 1 > 0)
                        ? Icons.star_half
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              SizedBox(width: 4),
              Text(
                "($reviewCount)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Build feature highlights
    Widget buildFeatureHighlights() {
      final features = [
        {"icon": Icons.verified, "text": "100% Authentic"},
        {"icon": Icons.local_shipping_outlined, "text": "Fast Delivery"},
        {"icon": Icons.refresh, "text": "Easy Returns"},
      ];

      return Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              features.map((feature) {
                return Column(
                  children: [
                    Icon(
                      feature["icon"] as IconData,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                    SizedBox(height: 4),
                    Text(
                      feature["text"] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      );
    }

    // Build product details tabs
    Widget buildProductDetailsTabs() {
      // If tab controller isn't initialized yet, show a placeholder
      if (_tabController == null) {
        return Container(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Column(
        children: [
          TabBar(
            controller: _tabController!,
            indicatorColor: Colors.green,
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: [
              Tab(text: "DETAILS"),
              Tab(text: "BENEFITS"),
              Tab(text: "REVIEWS"),
            ],
          ),
          Container(
            height: 150,
            padding: EdgeInsets.all(16),
            child: TabBarView(
              controller: _tabController!,
              children: [
                // Details tab - Ensuring description is properly shown
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Product Description",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Benefits tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• High in fiber for better digestion",
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• Rich in essential nutrients",
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• Made with premium quality ingredients",
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),

                // Reviews tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text(
                            ratings.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "based on $reviewCount reviews",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Sample review
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Verified Customer",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Great product, excellent quality. Will buy again!",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Similar products section removed as requested

    // Build the main content with proper layout
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          productName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main product image and indicators
                buildMainImage(),
                SizedBox(height: 12),
                Center(child: buildIndicators()),

                // Container for all other content with padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating and delivery info
                      buildRating(),
                      SizedBox(height: 16),

                      // Stock status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              stockStatus == "In Stock"
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stockStatus,
                          style: TextStyle(
                            color:
                                stockStatus == "In Stock"
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Product name and weight
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "$weight $unit",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Price information
                      Row(
                        children: [
                          Text(
                            "₹${currentPrice.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (hasDiscount) ...[
                            Text(
                              "MRP ₹${regularPrice.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$discountPercentage% OFF",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),

                      // Price per unit with error handling
                      Builder(
                        builder: (context) {
                          // Calculate price per unit safely
                          double pricePerUnit =
                              weightValue > 0
                                  ? currentPrice / weightValue
                                  : currentPrice;

                          return Text(
                            "₹${pricePerUnit.toStringAsFixed(2)}/100 g",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Feature highlights
                      buildFeatureHighlights(),

                      SizedBox(height: 24),

                      // Product details tabs
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: buildProductDetailsTabs(),
                      ),

                      SizedBox(height: 24),

                      // Brand section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              radius: 20,
                              child:
                                  brand.isNotEmpty
                                      ? Text(
                                        brand[0],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      )
                                      : Icon(Icons.store, color: Colors.grey),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    brand,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Explore all products",
                                    style: TextStyle(
                                      color: ThemeConfig.getPriceColor(
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),

                      // Extra space for bottom bar
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed bottom bar with add to cart button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: quantity > 1 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "$quantity",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              quantity++;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Icon(Icons.add, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Add to cart button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: addProductToCart,
                      child: Text(
                        "ADD TO CART  ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ThemeConfig.getAddToCartButtonStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
