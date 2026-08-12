class Product {
  final String id;
  final String fishName;
  final String category;
  final String description;
  final String imageUrl;

  final String exporterId;
  final String exporterName;

  final double price;
  final int quantity;

  final double rating;

  final bool isAvailable;

  Product({
    required this.id,
    required this.fishName,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.exporterId,
    required this.exporterName,
    required this.price,
    required this.quantity,
    required this.rating,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "fishName": fishName,
      "category": category,
      "description": description,
      "imageUrl": imageUrl,
      "exporterId": exporterId,
      "exporterName": exporterName,
      "price": price,
      "quantity": quantity,
      "rating": rating,
      "isAvailable": isAvailable,
    };
  }
}