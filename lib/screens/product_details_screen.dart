import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/models/cart_item.dart';
import 'package:trueway_ecommerce/providers/cart_provider.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/AddressScreen.dart';
import 'package:trueway_ecommerce/screens/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailsScreen({required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  int _selectedImageIndex = 0; // Track selected thumbnail index

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

    // Build the main product image carousel
    Widget buildMainImage() {
      return CarouselSlider(
        options: CarouselOptions(
          height: 300,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
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

    // Build the thumbnail row for image selection
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

    // Function to create a CartItem object from the current product
    CartItem createCartItemFromProduct() {
      String selectedImageUrl = "";
      if (images.isNotEmpty) {
        selectedImageUrl = images[_selectedImageIndex]["src"] ?? "";
      }

      return CartItem(
        id:
            widget.product["id"] is int
                ? widget.product["id"]
                : int.tryParse(widget.product["id"].toString()) ?? 0,
        name: productName,
        imageUrl: selectedImageUrl,
        price: currentPrice,
        image: "", // Not used
        quantity: quantity,
      );
    }

    // Function to add the current product to cart
    void addProductToCart(
      BuildContext context, {
      bool showNotification = true,
    }) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final cartItem = createCartItemFromProduct();

      cart.addToCart(cartItem);

      if (showNotification) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$productName added to cart!")));
      }
    }

    // Build the scrollable main content of the screen
    Widget buildScrollableContent() {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildMainImage(),
            SizedBox(height: 12),
            buildThumbnailRow(),
            SizedBox(height: 20),
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
            SizedBox(height: 8),
            Text(
              "₹$currentPrice",
              style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
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
            SizedBox(height: 20),
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
            ), // Extra space for scrolling above the fixed bottom
          ],
        ),
      );
    }

    // Build the fixed bottom section with improved spacing and styling
    Widget buildFixedBottomSection() {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -3),
              blurRadius: 12,
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
                  "Quantity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.remove, size: 24),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      "$quantity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          quantity++;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.flash_on),
                    label: Text("BUY NOW", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Add the product to cart first (without notification)
                      addProductToCart(context, showNotification: false);

                      // Then navigate to checkout
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add_shopping_cart),
                    label: Text("ADD TO CART", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Add to cart with notification
                      addProductToCart(context);
                    },
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
              // Handle wishlist functionality if needed
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
          buildScrollableContent(),
          Align(
            alignment: Alignment.bottomCenter,
            child: buildFixedBottomSection(),
          ),
        ],
      ),
    );
  }
}
