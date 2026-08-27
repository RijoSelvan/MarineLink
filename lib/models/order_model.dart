import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String fishName;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;
  final String exporterId;
  final String exporterName;

  OrderItem({
    required this.productId,
    required this.fishName,
    this.category = '',
    required this.price,
    required this.quantity,
    this.imageUrl = '',
    this.exporterId = '',
    this.exporterName = '',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId']?.toString() ?? '',
      fishName: map['fishName']?.toString() ?? map['name']?.toString() ?? 'Fish Product',
      category: map['category']?.toString() ?? '',
      price: _toDouble(map['price']),
      quantity: _toInt(map['quantity']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      exporterId: map['exporterId']?.toString() ?? '',
      exporterName: map['exporterName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'fishName': fishName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'exporterId': exporterId,
      'exporterName': exporterName,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }
}

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String exporterId;
  final List<String> exporterIds;
  final String deliveryAddress;
  final String city;
  final String pincode;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentId;
  final String status;
  final String shipmentStatus;
  final dynamic createdAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    this.buyerEmail = '',
    this.buyerPhone = '',
    this.exporterId = '',
    this.exporterIds = const [],
    required this.deliveryAddress,
    this.city = '',
    this.pincode = '',
    required this.items,
    required this.totalAmount,
    this.paymentMethod = 'Cash on Delivery',
    this.paymentStatus = 'Pending',
    this.paymentId = '',
    this.status = 'Pending',
    this.shipmentStatus = 'Not Shipped',
    this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawItems = map['items'] ?? map['products'] ?? [];
    List<OrderItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map>()
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    final rawExpIds = map['exporterIds'];
    List<String> parsedExpIds = [];
    if (rawExpIds is List) {
      parsedExpIds = rawExpIds.map((e) => e.toString()).toList();
    }

    return OrderModel(
      orderId: map['orderId']?.toString() ?? docId ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? 'Buyer',
      buyerEmail: map['buyerEmail']?.toString() ?? '',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      exporterId: map['exporterId']?.toString() ?? '',
      exporterIds: parsedExpIds,
      deliveryAddress: map['deliveryAddress']?.toString() ?? map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      pincode: map['pincode']?.toString() ?? '',
      items: parsedItems,
      totalAmount: _toDouble(map['totalAmount'] ?? map['totalPrice']),
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Pending',
      paymentId: map['paymentId']?.toString() ?? '',
      status: map['status']?.toString() ?? map['orderStatus']?.toString() ?? 'Pending',
      shipmentStatus: map['shipmentStatus']?.toString() ?? 'Not Shipped',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'exporterId': exporterId,
      'exporterIds': exporterIds,
      'deliveryAddress': deliveryAddress,
      'city': city,
      'pincode': pincode,
      'items': items.map((i) => i.toMap()).toList(),
      'products': items.map((i) => i.toMap()).toList(), // dual compatibility
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'status': status,
      'orderStatus': status, // dual compatibility
      'shipmentStatus': shipmentStatus,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
