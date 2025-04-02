class CartItem {
  final int id;
  final int variationId;
  final String name;
  final String? image;
  int quantity;
  double price;
  Map<String, String>? attributes;

  CartItem({
    required this.id,
    this.variationId = 0,
    required this.name,
    this.image,
    required this.quantity,
    required this.price,
    this.attributes,
    required imageUrl,
  });

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      variationId: json['variation_id'] ?? 0,
      name: json['name'],
      image: json['image'],
      quantity: json['quantity'],
      price: json['price']?.toDouble() ?? 0.0,
      attributes:
          json['attributes'] != null
              ? Map<String, String>.from(json['attributes'])
              : null,
      imageUrl: null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variation_id': variationId,
      'name': name,
      'image': image,
      'quantity': quantity,
      'price': price,
      'attributes': attributes,
    };
  }
}
