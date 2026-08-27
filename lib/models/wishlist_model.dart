import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String id;
  final String productId;
  final String fishName;
  final String category;
  final double price;
  final String imageUrl;
  final String exporterId;
  final String exporterName;
  final double rating;
  final dynamic addedAt;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.fishName,
    this.category = '',
    required this.price,
    this.imageUrl = '',
    this.exporterId = '',
    this.exporterName = '',
    this.rating = 0.0,
    this.addedAt,
  });

  factory WishlistItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return WishlistItem(
      id: docId ?? map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? map['id']?.toString() ?? docId ?? '',
      fishName: map['fishName']?.toString() ?? 'Fish Product',
      category: map['category']?.toString() ?? '',
      price: _toDouble(map['price']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      exporterId: map['exporterId']?.toString() ?? '',
      exporterName: map['exporterName']?.toString() ?? '',
      rating: _toDouble(map['rating']),
      addedAt: map['addedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'fishName': fishName,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'exporterId': exporterId,
      'exporterName': exporterName,
      'rating': rating,
      'addedAt': addedAt ?? FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
