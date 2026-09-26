import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // ================================================================
  // SEND NOTIFICATION
  // ================================================================
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    String orderId = '',
  }) async {
    if (userId.isEmpty) return;

    try {
      final docRef = _notificationsCol.doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        orderId: orderId,
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await docRef.set(notification.toMap());
      debugPrint('Notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  // ================================================================
  // STREAM USER NOTIFICATIONS
  // ================================================================
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort client-side by createdAt descending to avoid composite index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ================================================================
  // STREAM UNREAD COUNT
  // ================================================================
  Stream<int> getUnreadCountStream(String userId) {
    if (userId.isEmpty) return Stream.value(0);

    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ================================================================
  // MARK AS READ
  // ================================================================
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // ================================================================
  // MARK ALL AS READ
  // ================================================================
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // ================================================================
  // DELETE NOTIFICATION
  // ================================================================
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // ================================================================
  // CLEAR ALL NOTIFICATIONS FOR USER
  // ================================================================
  Future<void> clearAll(String userId) async {
    try {
      final docs = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}
