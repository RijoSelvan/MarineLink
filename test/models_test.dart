import 'package:flutter_test/flutter_test.dart';
import 'package:fish_export_management/models/user_model.dart';
import 'package:fish_export_management/models/product_model.dart';
import 'package:fish_export_management/models/order_model.dart';
import 'package:fish_export_management/models/fish_model.dart';
import 'package:fish_export_management/models/wishlist_model.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel fromMap and toMap', () {
      final user = UserModel(
        uid: 'user123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        role: 'Buyer',
        address: '123 Harbor Street',
        city: 'Kochi',
        pincode: '682001',
      );

      final map = user.toMap();
      expect(map['uid'], 'user123');
      expect(map['name'], 'John Doe');
      expect(map['role'], 'Buyer');

      final reconstructed = UserModel.fromMap(map, 'user123');
      expect(reconstructed.uid, 'user123');
      expect(reconstructed.email, 'john@example.com');
      expect(reconstructed.city, 'Kochi');
    });
  });

  group('OrderModel Tests', () {
    test('OrderModel serialization and fallback handling', () {
      final item = OrderItem(
        productId: 'prod1',
        fishName: 'Yellowfin Tuna',
        price: 450.0,
        quantity: 2,
        exporterId: 'exp1',
        exporterName: 'Ocean Catch',
      );

      final order = OrderModel(
        orderId: 'ord100',
        buyerId: 'buyer1',
        buyerName: 'Alice',
        deliveryAddress: 'Main Dock 4',
        items: [item],
        totalAmount: 900.0,
      );

      final map = order.toMap();
      expect(map['orderId'], 'ord100');
      expect(map['items'], isNotEmpty);
      expect(map['products'], isNotEmpty); // dual compatibility check

      final fromMap = OrderModel.fromMap(map, 'ord100');
      expect(fromMap.orderId, 'ord100');
      expect(fromMap.items.length, 1);
      expect(fromMap.items.first.fishName, 'Yellowfin Tuna');
      expect(fromMap.totalAmount, 900.0);
    });
  });

  group('ProductModel Tests', () {
    test('Product fromMap and toMap', () {
      final map = {
        'id': 'p1',
        'fishName': 'Salmon',
        'category': 'Fresh Fish',
        'description': 'Fresh Atlantic salmon',
        'imageUrl': 'https://example.com/salmon.jpg',
        'exporterId': 'exp2',
        'exporterName': 'Nordic Marine',
        'price': 600.0,
        'quantity': 50,
        'rating': 4.8,
        'isAvailable': true,
      };

      final product = Product.fromMap(map, 'p1');
      expect(product.id, 'p1');
      expect(product.fishName, 'Salmon');
      expect(product.price, 600.0);
      expect(product.quantity, 50);
      expect(product.isAvailable, true);
    });
  });

  group('FishModel Tests', () {
    test('FishModel fromMap and toMap', () {
      final fish = FishModel(
        id: 'f1',
        name: 'Mackerel',
        fishType: 'Mackerel',
        defaultPrice: 180.0,
      );

      final map = fish.toMap();
      expect(map['name'], 'Mackerel');
      expect(map['price'], 180.0);

      final reconstructed = FishModel.fromMap(map, 'f1');
      expect(reconstructed.name, 'Mackerel');
      expect(reconstructed.defaultPrice, 180.0);
    });
  });

  group('WishlistModel Tests', () {
    test('WishlistItem fromMap and toMap', () {
      final item = WishlistItem(
        id: 'w1',
        productId: 'prod5',
        fishName: 'King Prawns',
        price: 750.0,
        rating: 4.9,
      );

      final map = item.toMap();
      expect(map['fishName'], 'King Prawns');
      expect(map['price'], 750.0);

      final reconstructed = WishlistItem.fromMap(map, 'w1');
      expect(reconstructed.productId, 'prod5');
      expect(reconstructed.rating, 4.9);
    });
  });
}
