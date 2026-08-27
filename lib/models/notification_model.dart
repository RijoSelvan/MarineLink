import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'new_order', 'order_placed', 'order_accepted', 'order_shipped', 'order_delivered', 'order_cancelled', 'order_rejected', 'system'
  final String orderId;
  final bool isRead;
  final Timestamp createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.orderId = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String docId) {
    return NotificationModel(
      id: docId,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Notification',
      message: data['message']?.toString() ?? '',
      type: data['type']?.toString() ?? 'system',
      orderId: data['orderId']?.toString() ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}
