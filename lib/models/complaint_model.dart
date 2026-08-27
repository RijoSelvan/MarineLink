import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String? orderId;
  final String? fishName;
  final String complaintBy;
  final String complaintByName;
  final String complaintByEmail;
  final String complaintByRole; // 'Buyer' or 'Exporter'
  final String? accusedId;
  final String accusedName;
  final String accusedRole; // 'Exporter' or 'Buyer'
  final String type; // 'Cheating / Fraud', 'Quality Issue', etc.
  final String description;
  final String status; // 'Pending', 'Investigating', 'Validated (Cheating Confirmed)', 'Resolved', 'Dismissed'
  final String? adminRemarks;
  final String? adminId;
  final DateTime createdAt;
  final DateTime? validatedAt;

  Complaint({
    required this.id,
    this.orderId,
    this.fishName,
    required this.complaintBy,
    required this.complaintByName,
    required this.complaintByEmail,
    required this.complaintByRole,
    this.accusedId,
    required this.accusedName,
    required this.accusedRole,
    required this.type,
    required this.description,
    required this.status,
    this.adminRemarks,
    this.adminId,
    required this.createdAt,
    this.validatedAt,
  });

  factory Complaint.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Complaint.fromMap(data, doc.id);
  }

  factory Complaint.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Complaint(
      id: map['id']?.toString() ?? docId ?? '',
      orderId: map['orderId']?.toString(),
      fishName: map['fishName']?.toString(),
      complaintBy: map['complaintBy']?.toString() ?? '',
      complaintByName: map['complaintByName']?.toString() ?? 'User',
      complaintByEmail: map['complaintByEmail']?.toString() ?? '',
      complaintByRole: map['complaintByRole']?.toString() ?? 'Buyer',
      accusedId: map['accusedId']?.toString(),
      accusedName: map['accusedName']?.toString() ?? 'Unspecified',
      accusedRole: map['accusedRole']?.toString() ?? 'Exporter',
      type: map['type']?.toString() ?? 'Cheating / Fraud',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Pending',
      adminRemarks: map['adminRemarks']?.toString(),
      adminId: map['adminId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      validatedAt: map['validatedAt'] != null ? parseDate(map['validatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'fishName': fishName,
      'complaintBy': complaintBy,
      'complaintByName': complaintByName,
      'complaintByEmail': complaintByEmail,
      'complaintByRole': complaintByRole,
      'accusedId': accusedId,
      'accusedName': accusedName,
      'accusedRole': accusedRole,
      'type': type,
      'description': description,
      'status': status,
      'adminRemarks': adminRemarks,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
    };
  }
}
