import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/complaint_model.dart';
import 'notification_service.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _firestore.collection('complaints');

  /// Submits a new cheating or operational complaint to the Admin
  Future<String?> submitComplaint(Complaint complaint) async {
    try {
      final docRef = complaint.id.isNotEmpty
          ? _complaintsRef.doc(complaint.id)
          : _complaintsRef.doc();

      final data = complaint.toMap();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);

      // 1. Notify complainant
      await _notificationService.notifyUser(
        userId: complaint.complaintBy,
        title: 'Complaint Registered ⚖️',
        message:
            'Your grievance against ${complaint.accusedName} (${complaint.type}) has been lodged with Admin for review.',
        type: 'complaint_lodged',
        orderId: complaint.orderId ?? '',
      );

      // 2. Notify all Admin accounts
      try {
        final adminDocs = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();

        for (final adminDoc in adminDocs.docs) {
          await _notificationService.notifyUser(
            userId: adminDoc.id,
            title: 'New Cheating/Dispute Report ⚠️',
            message:
                '${complaint.complaintByName} (${complaint.complaintByRole}) reported ${complaint.accusedName} for: ${complaint.type}.',
            type: 'admin_dispute_alert',
            orderId: complaint.orderId ?? '',
          );
        }
      } catch (e) {
        debugPrint('Error notifying admins about complaint: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      return null;
    }
  }

  /// Real-time stream of all complaints for Admin oversight (in-memory sort/filter prevents composite index crashes)
  Stream<List<Complaint>> getAllComplaintsStream({String? statusFilter}) {
    return _complaintsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromFirestore(doc))
          .toList();

      // Sort client-side by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (statusFilter == null || statusFilter == 'All') {
        return list;
      }

      final filterLower = statusFilter.trim().toLowerCase();

      return list.where((c) {
        final st = c.status.trim().toLowerCase();
        if (filterLower == 'pending') {
          return st == 'pending' || st.isEmpty;
        }
        if (filterLower == 'completed' ||
            filterLower == 'resolved' ||
            filterLower.contains('completed') ||
            filterLower.contains('resolved')) {
          return st == 'completed' || st == 'resolved';
        }
        if (filterLower.contains('validated') ||
            filterLower.contains('cheating')) {
          return st.contains('validated') || st.contains('cheating');
        }
        if (filterLower.contains('dismissed')) {
          return st.contains('dismissed');
        }
        return st == filterLower;
      }).toList();
    });
  }

  /// Real-time stream of complaints filed by or against a user
  Stream<List<Complaint>> getUserComplaintsStream(String userId) {
    return _complaintsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromFirestore(doc))
          .where((c) => c.complaintBy == userId || c.accusedId == userId)
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }


  /// Admin validates a cheating complaint or marks it resolved/dismissed
  Future<bool> validateComplaint({
    required String complaintId,
    required String newStatus, // 'Validated (Cheating Confirmed)', 'Resolved', 'Dismissed', 'Investigating'
    required String adminRemarks,
    required String adminId,
    required Complaint complaint,
  }) async {
    try {
      await _complaintsRef.doc(complaintId).update({
        'status': newStatus,
        'adminRemarks': adminRemarks.trim(),
        'adminId': adminId,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final bool isCheatingConfirmed =
          newStatus.toLowerCase().contains('validated');

      // 1. Notify Complainant
      await _notificationService.notifyUser(
        userId: complaint.complaintBy,
        title: isCheatingConfirmed
            ? 'Complaint Validated by Admin! ✅'
            : 'Complaint Status Update 📋',
        message:
            'Admin has reviewed your report against ${complaint.accusedName}. Verdict: $newStatus.\nRemarks: $adminRemarks',
        type: 'complaint_decision',
        orderId: complaint.orderId ?? '',
      );

      // 2. Notify Accused party if known
      if (complaint.accusedId != null && complaint.accusedId!.isNotEmpty) {
        await _notificationService.notifyUser(
          userId: complaint.accusedId!,
          title: isCheatingConfirmed
              ? 'Warning: Complaint Validated Against You ⚠️'
              : 'Admin Dispute Resolution Notice ⚖️',
          message: isCheatingConfirmed
              ? 'Admin has confirmed a cheating/non-compliance violation regarding order #${complaint.orderId ?? 'N/A'}.\nAdmin note: $adminRemarks'
              : 'Admin dispute case #${complaintId.substring(0, 6)} has been updated to: $newStatus.',
          type: 'compliance_notice',
          orderId: complaint.orderId ?? '',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error validating complaint: $e');
      return false;
    }
  }
}
