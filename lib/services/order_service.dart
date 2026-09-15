import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  // ================================================================
  // CREATE ORDER
  // ================================================================
  Future<String?> createOrder(OrderModel order) async {
    try {
      final docRef = order.orderId.isNotEmpty
          ? _ordersCollection.doc(order.orderId)
          : _ordersCollection.doc();

      final data = order.toMap();
      data['orderId'] = docRef.id;

      await docRef.set(data);

      // Decrement product stock
      for (final item in order.items) {
        try {
          final prodId = item.productId.trim();
          final orderedQty = item.quantity;
          if (prodId.isNotEmpty && orderedQty > 0) {
            final prodRef = _firestore.collection('products').doc(prodId);
            await _firestore.runTransaction((transaction) async {
              final prodSnap = await transaction.get(prodRef);
              if (prodSnap.exists && prodSnap.data() != null) {
                final currentStock =
                    (prodSnap.data()?['quantity'] as num?)?.toInt() ?? 0;
                final newStock = (currentStock - orderedQty).clamp(0, 999999999);
                final bool stillAvailable = newStock > 0;
                transaction.update(prodRef, {
                  'quantity': newStock,
                  'isAvailable': stillAvailable,
                  'status': stillAvailable ? 'Available' : 'Out of Stock',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            });
          }
        } catch (stockErr) {
          debugPrint('Error decreasing stock in OrderService: $stockErr');
        }
      }

      // Notify Buyer & Exporter(s)

      try {
        await _notificationService.notifyUser(
          userId: order.buyerId,
          title: 'Order Placed Successfully! 🛍️',
          message:
              'Your order #${docRef.id.length > 8 ? docRef.id.substring(0, 8) : docRef.id} has been placed (${order.paymentMethod}).',
          type: 'order_placed',
          orderId: docRef.id,
        );

        final Set<String> exporters = Set<String>.from(order.exporterIds);
        if (order.exporterId.isNotEmpty) exporters.add(order.exporterId);

        final fishName =
            order.items.isNotEmpty ? order.items.first.fishName : 'seafood';

        for (final expId in exporters) {
          await _notificationService.notifyUser(
            userId: expId,
            title: 'New Order Received! 🎣',
            message:
                '${order.buyerName} placed an order for $fishName (₹${order.totalAmount.toStringAsFixed(2)}).',
            type: 'new_order',
            orderId: docRef.id,
          );
        }
      } catch (err) {
        debugPrint('Error triggering notification on createOrder: $err');
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to place order.';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // ================================================================
  // GET BUYER ORDERS STREAM
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> getBuyerOrdersStream(String buyerId) {
    return _ordersCollection
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ================================================================
  // GET EXPORTER ORDERS STREAM
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> getExporterOrdersStream(String exporterId) {
    return _ordersCollection
        .where('exporterId', isEqualTo: exporterId)
        .snapshots();
  }

  // ================================================================
  // GET ALL ORDERS (FOR ADMIN)
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrdersStream() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ================================================================
  // UPDATE ORDER STATUS
  // ================================================================
  Future<String?> updateOrderStatus(String orderId, String status) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      final data = doc.data();

      final Map<String, dynamic> updates = {
        'status': status,
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'Processing') {
        updates['shipmentStatus'] = 'Preparing';
      } else if (status == 'Shipped') {
        updates['shipmentStatus'] = 'Shipped';
      } else if (status == 'In Transit') {
        updates['shipmentStatus'] = 'In Transit';
      } else if (status == 'Delivered' || status == 'Completed') {
        updates['shipmentStatus'] = 'Delivered';
      }

      await _ordersCollection.doc(orderId).update(updates);

      if (data != null) {
        final buyerId = data['buyerId']?.toString() ?? '';
        final fishName = data['fishName']?.toString() ?? 'seafood product';
        if (buyerId.isNotEmpty) {
          String notifType = 'system';
          if (status == 'Accepted') notifType = 'order_accepted';
          if (status == 'Rejected') notifType = 'order_rejected';
          if (status == 'Shipped' || status == 'In Transit') notifType = 'order_shipped';
          if (status == 'Completed' || status == 'Delivered') notifType = 'order_delivered';

          await _notificationService.notifyUser(
            userId: buyerId,
            title: 'Order Status: $status',
            message: 'Your order for $fishName status has been updated to $status.',
            type: notifType,
            orderId: orderId,
          );
        }
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update order status';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ================================================================
  // UPDATE SHIPMENT STATUS
  // ================================================================
  Future<String?> updateShipmentStatus(String orderId, String shipmentStatus) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      final data = doc.data();

      final Map<String, dynamic> updates = {
        'shipmentStatus': shipmentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (shipmentStatus == 'Preparing') {
        updates['status'] = 'Processing';
        updates['orderStatus'] = 'Processing';
      } else if (shipmentStatus == 'Shipped') {
        updates['status'] = 'Shipped';
        updates['orderStatus'] = 'Shipped';
      } else if (shipmentStatus == 'In Transit') {
        updates['status'] = 'In Transit';
        updates['orderStatus'] = 'In Transit';
      } else if (shipmentStatus == 'Delivered') {
        updates['status'] = 'Delivered';
        updates['orderStatus'] = 'Delivered';
      }

      await _ordersCollection.doc(orderId).update(updates);

      if (data != null) {
        final buyerId = data['buyerId']?.toString() ?? '';
        final fishName = data['fishName']?.toString() ?? 'seafood consignment';
        if (buyerId.isNotEmpty) {
          await _notificationService.notifyUser(
            userId: buyerId,
            title: 'Shipment: $shipmentStatus',
            message: 'Shipment status for $fishName is now: $shipmentStatus.',
            type: shipmentStatus == 'Delivered' ? 'order_delivered' : 'order_shipped',
            orderId: orderId,
          );
        }
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update shipment status';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ================================================================
  // CANCEL ORDER (BY BUYER)
  // ================================================================
  Future<String?> cancelOrder(String orderId, {String reason = 'Cancelled by customer'}) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      final data = doc.data();

      await _ordersCollection.doc(orderId).update({
        'status': 'Cancelled',
        'orderStatus': 'Cancelled',
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (data != null) {
        final buyerId = data['buyerId']?.toString() ?? '';
        final buyerName = data['buyerName']?.toString() ?? 'Buyer';
        final fishName = data['fishName']?.toString() ?? 'order';
        final primaryExporterId = data['exporterId']?.toString() ?? '';
        final dynamic rawExpIds = data['exporterIds'];
        final Set<String> exporters = {};
        if (rawExpIds is List) {
          for (final exp in rawExpIds) {
            if (exp != null && exp.toString().isNotEmpty) exporters.add(exp.toString());
          }
        }
        if (primaryExporterId.isNotEmpty) exporters.add(primaryExporterId);

        if (buyerId.isNotEmpty) {
          await _notificationService.notifyUser(
            userId: buyerId,
            title: 'Order Cancelled',
            message: 'Your order for $fishName was cancelled.',
            type: 'order_cancelled',
            orderId: orderId,
          );
        }

        for (final expId in exporters) {
          await _notificationService.notifyUser(
            userId: expId,
            title: 'Order Cancelled ⚠️',
            message: '$buyerName cancelled the order for $fishName.',
            type: 'order_cancelled',
            orderId: orderId,
          );
        }
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to cancel order';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
