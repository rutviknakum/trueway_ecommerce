class CartItem {
  final int id;
  final String name;
  final String image;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });
}
