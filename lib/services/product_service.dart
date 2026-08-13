import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

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
    // =========================
  // ADD TO CART
  // =========================

  Future<String?> addToCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      final cartDocument = _firestore
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(product.id);

      await cartDocument.set({
        "productId": product.id,
        "fishName": product.fishName,
        "category": product.category,
        "price": product.price,
        "quantity": quantity,
        "imageUrl": product.imageUrl,
        "exporterId": product.exporterId,
        "exporterName": product.exporterName,
        "addedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to add product to cart";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // GET CART
  // =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> getCart() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("users")
        .doc(user.uid)
        .collection("cart")
        .snapshots();
  }

  // =========================
  // UPDATE CART QUANTITY
  // =========================

  Future<String?> updateCartQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      if (quantity <= 0) {
        await _firestore
            .collection("users")
            .doc(user.uid)
            .collection("cart")
            .doc(productId)
            .delete();

        return null;
      }

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .update({
        "quantity": quantity,
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to update cart";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // REMOVE FROM CART
  // =========================

  Future<String?> removeFromCart(String productId) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .delete();

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to remove item";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }
    // =========================
  // ADD TO WISHLIST
  // =========================

  Future<String?> addToWishlist({
    required Product product,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      final wishlistDocument = _firestore
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(product.id);

      await wishlistDocument.set({
        "productId": product.id,
        "fishName": product.fishName,
        "category": product.category,
        "description": product.description,
        "price": product.price,
        "quantity": product.quantity,
        "imageUrl": product.imageUrl,
        "exporterId": product.exporterId,
        "exporterName": product.exporterName,
        "rating": product.rating,
        "isAvailable": product.isAvailable,
        "addedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to add to wishlist";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // GET WISHLIST
  // =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> getWishlist() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .orderBy(
          "addedAt",
          descending: true,
        )
        .snapshots();
  }

  // =========================
  // REMOVE FROM WISHLIST
  // =========================

  Future<String?> removeFromWishlist(
    String productId,
  ) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        return "User is not logged in";
      }

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(productId)
          .delete();

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? "Failed to remove from wishlist";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // =========================
  // CHECK WISHLIST
  // =========================

  Future<bool> isInWishlist(
    String productId,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final document = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .doc(productId)
        .get();

    return document.exists;
  }
  

  
}