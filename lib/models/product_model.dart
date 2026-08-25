import '../utils/category_helper.dart';
import '../utils/stock_helper.dart';

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
  final String? godownAddress;

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
    this.godownAddress,
  });

  // Stock helpers (1 box = 50 kg, 1 ton = 20 boxes = 1000 kg)
  bool get isOutOfStock => !isAvailable || quantity <= 0;
  int get boxes => StockHelper.toBoxes(quantity);
  double get tons => StockHelper.toTons(quantity);
  String get stockDetailed => StockHelper.formatStockDetailed(quantity);
  String get stockBadge => StockHelper.formatStockBadge(quantity);


  // ============================================================
  // FIRESTORE -> PRODUCT
  // ============================================================

  factory Product.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawCategory = map['category']?.toString();
    final rawFishType = map['fishType']?.toString();
    final rawFishName = map['fishName']?.toString() ?? '';
    final rawDescription = map['description']?.toString() ?? '';

    final resolvedCategory = CategoryHelper.determineCategory(
      category: rawCategory,
      fishType: rawFishType,
      fishName: rawFishName,
      description: rawDescription,
    );

    final quantity = _toInt(map['quantity']);

    final isAvailableVal = map['isAvailable'];
    final statusVal = map['status']?.toString().toLowerCase().trim();

    final bool isExplicitlyUnavailable = isAvailableVal == false ||
        statusVal == 'unavailable' ||
        statusVal == 'out of stock' ||
        quantity <= 0;

    final bool available = !isExplicitlyUnavailable &&
        (isAvailableVal == true || statusVal == 'available' || quantity > 0);


    final String rawImageUrl = map['imageUrl']?.toString() ?? '';
    final String finalImageUrl = rawImageUrl.trim().isNotEmpty &&
            rawImageUrl.startsWith('http')
        ? rawImageUrl
        : '';

    return Product(
      id: map['id']?.toString().isNotEmpty == true
          ? map['id'].toString()
          : (docId ?? ''),
      fishName: rawFishName,
      category: resolvedCategory,
      description: rawDescription,
      imageUrl: finalImageUrl,
      exporterId: map['exporterId']?.toString() ?? '',
      exporterName: map['exporterName']?.toString() ?? 'Exporter',
      price: _toDouble(map['price']),
      quantity: quantity,
      rating: _toDouble(map['rating']),
      isAvailable: available,
      godownAddress: map['godownAddress']?.toString(),
    );
  }

  // ============================================================
  // PRODUCT -> FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fishName': fishName,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'exporterId': exporterId,
      'exporterName': exporterName,
      'price': price,
      'quantity': quantity,
      'rating': rating,
      'isAvailable': isAvailable,
      'godownAddress': godownAddress,
    };
  }

  // ============================================================
  // SAFE DOUBLE CONVERSION
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // ============================================================
  // SAFE INTEGER CONVERSION
  // ============================================================

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ??
          double.tryParse(value)?.toInt() ??
          0;
    }

    return 0;
  }
}