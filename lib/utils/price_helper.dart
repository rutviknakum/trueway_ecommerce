class PriceInfo {
  final double price;
  final double regularPrice;
  final bool hasDiscount;
  final double discountPercentage;

  PriceInfo({
    required this.price,
    required this.regularPrice,
    required this.hasDiscount,
    required this.discountPercentage,
  });
}

class PriceHelper {
  /// Extracts and calculates price information from a product
  static PriceInfo getPriceInfo(dynamic product) {
    // Handle prices safely
    final String priceStr = product["price"]?.toString() ?? "0";
    final String regularPriceStr = product["regular_price"]?.toString() ?? "0";

    // Parse prices carefully
    double price = 0.0;
    double regularPrice = 0.0;
    try {
      price = double.parse(priceStr);
      regularPrice = double.parse(regularPriceStr);
    } catch (e) {
      print("Error parsing price: $e");
    }

    final bool hasDiscount = regularPrice > 0 && regularPrice != price;
    final discountPercentage =
        hasDiscount ? ((regularPrice - price) / regularPrice * 100) : 0;

    return PriceInfo(
      price: price,
      regularPrice: regularPrice,
      hasDiscount: hasDiscount,
      discountPercentage: discountPercentage.toDouble(),
    );
  }
}
