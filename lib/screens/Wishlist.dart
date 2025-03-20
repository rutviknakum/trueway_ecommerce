import 'package:flutter/material.dart';

class WishlistScreen extends StatelessWidget {
  final List wishlist;

  WishlistScreen({required this.wishlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wishlist")),
      body:
          wishlist.isEmpty
              ? Center(child: Text("Your wishlist is empty"))
              : ListView.builder(
                itemCount: wishlist.length,
                itemBuilder: (context, index) {
                  final product = wishlist[index];
                  return ListTile(
                    leading: Image.network(
                      product["images"][0]["src"],
                      width: 50,
                    ),
                    title: Text(product["name"]),
                    subtitle: Text("₹${product["price"]}"),
                  );
                },
              ),
    );
  }
}
