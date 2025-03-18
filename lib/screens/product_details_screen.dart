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

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = widget.product["images"] ?? [];
    String productName = widget.product["name"] ?? "Unknown Product";
    String productPrice =
        widget.product["price"] != null
            ? "₹${widget.product["price"]}"
            : "Price not available";
    String stockStatus =
        widget.product["stock_status"] == "instock"
            ? "In Stock"
            : "Out of Stock";
    String description =
        widget.product["description"]?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        "No description available";

    return Scaffold(
      appBar: AppBar(
        title: Text(productName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 **Product Images Carousel**
            CarouselSlider(
              options: CarouselOptions(
                height: 300,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
              items:
                  images.isNotEmpty
                      ? images.map((img) {
                        return CachedNetworkImage(
                          imageUrl: img["src"],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }).toList()
                      : [
                        Image.network(
                          "https://via.placeholder.com/300",
                          fit: BoxFit.cover,
                        ),
                      ],
            ),

            /// 🔹 **Product Info Section**
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        productPrice,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        stockStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              stockStatus == "In Stock"
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  //    SizedBox(height: 5),

                  /// 🔹 **Quantity Selector**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Quantity:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                  SizedBox(height: 20),

                  /// 🔹 **Add to Cart & Buy Now Buttons**
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            final cart = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );

                            print("Adding to cart: ${widget.product["name"]}");

                            cart.addToCart(
                              CartItem(
                                id:
                                    widget.product["id"] is int
                                        ? widget.product["id"]
                                        : int.tryParse(
                                              widget.product["id"].toString(),
                                            ) ??
                                            0, // Ensure `id` is int
                                name:
                                    widget.product["name"] ?? "Unknown Product",
                                image:
                                    widget.product["images"].isNotEmpty
                                        ? widget.product["images"][0]["src"]
                                        : "",
                                price:
                                    widget.product["price"] is String
                                        ? double.tryParse(
                                              widget.product["price"],
                                            ) ??
                                            0.0
                                        : widget.product["price"].toDouble(),
                                imageUrl: '', // Ensure `price` is double
                              ),
                            );

                            print("Cart Items: ${cart.items.length}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(" added to cart!")),
                            );
                          },

                          child: Text(
                            "Add to Cart",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {},
                          child: Text(
                            "Buy Now",
                            style: TextStyle(fontSize: 18),
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
    );
  }
}
