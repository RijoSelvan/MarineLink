import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String address;
  final String city;
  final String pincode;
  final String companyName;
  final dynamic createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address = '',
    this.city = '',
    this.pincode = '',
    this.companyName = '',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      uid: map['uid']?.toString() ?? docId ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Buyer',
      address: map['address']?.toString() ?? map['deliveryAddress']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      pincode: map['pincode']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'city': city,
      'pincode': pincode,
      'companyName': companyName,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? pincode,
    String? companyName,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      companyName: companyName ?? this.companyName,
      createdAt: createdAt,
    );
  }
}
