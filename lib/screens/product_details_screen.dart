import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailsScreen({required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  int _selectedImageIndex = 0; // Track which thumbnail is selected

  @override
  Widget build(BuildContext context) {
    // Safely extract product data
    List<dynamic> images = widget.product["images"] ?? [];
    String productName = widget.product["name"] ?? "Unknown Product";
    String productPriceStr = widget.product["price"]?.toString() ?? "0.0";
    double currentPrice = double.tryParse(productPriceStr) ?? 0.0;
    String regularPriceStr =
        widget.product["regular_price"]?.toString() ?? productPriceStr;
    double regularPrice = double.tryParse(regularPriceStr) ?? currentPrice;
    bool hasDiscount = regularPrice > currentPrice;
    double discountPercentage =
        hasDiscount
            ? ((regularPrice - currentPrice) / regularPrice) * 100
            : 0.0;
    String stockStatus =
        widget.product["stock_status"] == "instock"
            ? "In Stock"
            : "Out of Stock";
    String description =
        widget.product["description"]?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        "No description available";

    // Main image URL from the selected thumbnail or fallback placeholder

    // Build the main product image carousel
    Widget buildMainImage() {
      return CarouselSlider(
        options: CarouselOptions(
          height: 300,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
        ),
        items:
            images.isNotEmpty
                ? images.map((img) {
                  return CachedNetworkImage(
                    imageUrl: img["src"] ?? "https://via.placeholder.com/300",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  );
                }).toList()
                : [
                  Image.network(
                    "https://via.placeholder.com/300",
                    fit: BoxFit.cover,
                  ),
                ],
      );
    }

    // Build thumbnail row for selecting images
    Widget buildThumbnailRow() {
      if (images.isEmpty) return SizedBox.shrink();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(images.length, (index) {
            String thumbUrl =
                images[index]["src"] ?? "https://via.placeholder.com/100";
            bool isSelected = _selectedImageIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: thumbUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            );
          }),
        ),
      );
    }

    // Build the scrollable content (everything except quantity & buttons)
    Widget buildScrollableContent() {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main product image carousel
            buildMainImage(),
            SizedBox(height: 10),
            // Thumbnails for image selection
            buildThumbnailRow(),
            SizedBox(height: 20),
            // Product title and sale label
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    productName.toUpperCase(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasDiscount)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "Sale ${discountPercentage.toStringAsFixed(0)}%",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            // Price
            Text(
              "₹$currentPrice",
              style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            // SKU & Availability (if available)
            Text(
              "SKU: ${widget.product['sku'] ?? 'TW00016'}",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Text(
                  "Availability: ",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  stockStatus,
                  style: TextStyle(
                    color:
                        stockStatus == "In Stock" ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Wishlist placeholder text (if needed)
            Text(
              "[yith_wcwl_add_to_wishlist]",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            // Description Section
            Text(
              "DESCRIPTION",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(
              height: 100,
            ), // Extra space so content can scroll above the fixed bottom
          ],
        ),
      );
    }

    // Build fixed bottom section for quantity and buttons (not scrollable)
    Widget buildFixedBottomSection() {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quantity:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                    ),
                    Text(
                      "$quantity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            // Action Buttons: Buy Now & Add to Cart
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Implement Buy Now functionality
                    },
                    child: Text("BUY NOW", style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final cart = Provider.of<CartProvider>(
                        context,
                        listen: false,
                      );
                      cart.addToCart(
                        CartItem(
                          id:
                              widget.product["id"] is int
                                  ? widget.product["id"]
                                  : int.tryParse(
                                        widget.product["id"].toString(),
                                      ) ??
                                      0,
                          name: productName,
                          image:
                              images.isNotEmpty
                                  ? images[_selectedImageIndex]["src"]
                                  : "",
                          price: currentPrice,
                          imageUrl: '',
                          quantity: quantity, // Pass the selected quantity
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$productName added to cart!")),
                      );
                    },
                    child: Text("ADD TO CART", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // Handle wishlist functionality here
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
      // The main content scrolls, while the bottom section is fixed.
      body: Stack(
        children: [
          buildScrollableContent(),
          // Fixed bottom section (using Align to position at the bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: buildFixedBottomSection(),
          ),
        ],
      ),
    );
  }
}
