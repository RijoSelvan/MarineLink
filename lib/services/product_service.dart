import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================
  // ADD PRODUCT
  // =========================

  Future<String?> addProduct({
    required String fishName,
    required String category,
    required String description,
    required double price,
    required int quantity,
    required String imageUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      // Get exporter details
      final userDocument = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      String exporterName = "Exporter";

      if (userDocument.exists) {
        final data = userDocument.data();

        if (data != null && data["name"] != null) {
          exporterName = data["name"].toString();
        }
      }

      // Create product document
      final productDocument =
          _firestore.collection("products").doc();

      await productDocument.set({
        "id": productDocument.id,
        "fishName": fishName,
        "category": category,
        "description": description,
        "price": price,
        "quantity": quantity,
        "imageUrl": imageUrl,
        "exporterId": user.uid,
        "exporterName": exporterName,
        "rating": 0.0,
        "isAvailable": quantity > 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Firebase error occurred";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // GET ALL PRODUCTS
  // =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> getProducts() {
    return _firestore
        .collection("products")
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots();
  }

  // =========================
  // GET EXPORTER PRODUCTS
  // =========================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getExporterProducts() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("products")
        .where(
          "exporterId",
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  // =========================
  // DELETE PRODUCT
  // =========================

  Future<String?> deleteProduct(
    String productId,
  ) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      await _firestore
          .collection("products")
          .doc(productId)
          .delete();

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to delete product";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // UPDATE PRODUCT
  // =========================

  Future<String?> updateProduct({
    required String productId,
    required String fishName,
    required String category,
    required String description,
    required double price,
    required int quantity,
    required String imageUrl,
  }) async {
    try {
      await _firestore
          .collection("products")
          .doc(productId)
          .update({
        "fishName": fishName,
        "category": category,
        "description": description,
        "price": price,
        "quantity": quantity,
        "imageUrl": imageUrl,
        "isAvailable": quantity > 0,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to update product";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }
}