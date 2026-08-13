import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'buyer_product_details_screen.dart';

class BuyerWishlistScreen extends StatelessWidget {
  const BuyerWishlistScreen({super.key});

  static const Color primaryColor = Color(0xff0A4D68);

  static final ProductService productService = ProductService();

  Product _productFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Product(
      id: data["productId"]?.toString() ?? document.id,
      fishName: data["fishName"]?.toString() ?? "",
      category: data["category"]?.toString() ?? "",
      description: data["description"]?.toString() ?? "",
      imageUrl: data["imageUrl"]?.toString() ?? "",
      exporterId: data["exporterId"]?.toString() ?? "",
      exporterName: data["exporterName"]?.toString() ?? "Exporter",
      price: _toDouble(data["price"]),
      quantity: _toInt(data["quantity"]),
      rating: _toDouble(data["rating"]),
      isAvailable: data["isAvailable"] == true,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Wishlist",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productService.getWishlist(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Unable to load wishlist",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          // Empty wishlist
          if (documents.isEmpty) {
            return _emptyWishlist();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];

              final Product product =
                  _productFromDocument(document);

              return _wishlistCard(
                context,
                product,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY WISHLIST
  // ============================================================

  Widget _emptyWishlist() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Your Wishlist is Empty",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Save your favourite seafood products here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WISHLIST CARD
  // ============================================================

  Widget _wishlistCard(
    BuildContext context,
    Product product,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BuyerProductDetailsScreen(
                product: product,
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Row(
            children: [
              // Product Image
              _productImage(product),

              const SizedBox(width: 14),

              // Product Information
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.fishName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      product.category,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "₹${product.price.toStringAsFixed(0)}/kg",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            product.exporterName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove Button
              IconButton(
                tooltip: "Remove from wishlist",

                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 30,
                ),

                onPressed: () {
                  _removeFromWishlist(
                    context,
                    product,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(Product product) {
    if (product.imageUrl.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xffE8F4F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.set_meal,
          size: 45,
          color: primaryColor,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        product.imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 90,
            height: 90,
            color: const Color(0xffE8F4F8),
            child: const Icon(
              Icons.image_not_supported,
              color: primaryColor,
              size: 35,
            ),
          );
        },

        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: 90,
            height: 90,
            color: const Color(0xffE8F4F8),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // REMOVE WISHLIST ITEM
  // ============================================================

  Future<void> _removeFromWishlist(
    BuildContext context,
    Product product,
  ) async {
    final result =
        await productService.removeFromWishlist(
      product.id,
    );

    if (!context.mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Removed from wishlist",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}