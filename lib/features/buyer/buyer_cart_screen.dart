import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/product_service.dart';
import 'buyer_checkout_screen.dart';

class BuyerCartScreen extends StatefulWidget {
  const BuyerCartScreen({super.key});

  @override
  State<BuyerCartScreen> createState() => _BuyerCartScreenState();
}

class _BuyerCartScreenState extends State<BuyerCartScreen> {
  final ProductService productService = ProductService();

  bool isRemoving = false;

  // ================================================================
  // REMOVE ITEM FROM CART
  // ================================================================

  Future<void> _removeFromCart(String cartItemId) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
        Colors.red,
      );
      return;
    }

    try {
      setState(() {
        isRemoving = true;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartItemId)
          .delete();

      if (!mounted) return;

      setState(() {
        isRemoving = false;
      });

      _showMessage(
        'Item removed from cart.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isRemoving = false;
      });

      _showMessage(
        'Failed to remove item.',
        Colors.red,
      );
    }
  }

  // ================================================================
  // CLEAR CART
  // ================================================================

  Future<void> _clearCart(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
  ) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || items.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('CLEAR'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final WriteBatch batch =
          FirebaseFirestore.instance.batch();

      for (final item in items) {
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(item.id),
        );
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        'Cart cleared.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to clear cart.',
        Colors.red,
      );
    }
  }

  // ================================================================
  // CHECKOUT
  // ================================================================

  void _goToCheckout(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
  ) {
    if (items.isEmpty) {
      _showMessage(
        'Your cart is empty.',
        Colors.orange,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerCheckoutScreen(),
      ),
    );
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Cart',
        ),
        actions: [
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: productService.getCart(),
            builder: (context, snapshot) {
              final items =
                  snapshot.data?.docs ?? [];

              if (items.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear Cart',
                icon: const Icon(
                  Icons.delete_sweep,
                ),
                onPressed: isRemoving
                    ? null
                    : () {
                        _clearCart(items);
                      },
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: productService.getCart(),

        builder: (context, snapshot) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff0A4D68),
              ),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load your cart.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          final items =
              snapshot.data?.docs ?? [];

          // ========================================================
          // EMPTY CART
          // ========================================================

          if (items.isEmpty) {
            return _emptyCart();
          }

          // ========================================================
          // CALCULATE TOTAL
          // ========================================================

          double total = 0;

          for (final item in items) {
            final data = item.data();

            final double price =
                _toDouble(data['price']);

            final int quantity =
                _toInt(data['quantity']);

            total += price * quantity;
          }

          // ========================================================
          // CART CONTENT
          // ========================================================

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return _cartItem(
                      item,
                    );
                  },
                ),
              ),

              // ====================================================
              // BOTTOM SUMMARY
              // ====================================================

              _bottomSummary(
                items,
                total,
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // EMPTY CART
  // ================================================================

  Widget _emptyCart() {
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
                color: const Color(0xffE8F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Color(0xff0A4D68),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Browse seafood products and add them to your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff0A4D68),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 14,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.shopping_bag,
              ),
              label: const Text(
                'Browse Products',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CART ITEM
  // ================================================================

  Widget _cartItem(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final String fishName =
        data['fishName']?.toString() ??
            'Fish Product';

    final String category =
        data['category']?.toString() ??
            'Seafood';

    final String imageUrl =
        data['imageUrl']?.toString() ??
            '';

    final String exporterName =
        data['exporterName']?.toString() ??
            'Exporter';

    final double price =
        _toDouble(data['price']);

    final int quantity =
        _toInt(data['quantity']);

    final double itemTotal =
        price * quantity;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // PRODUCT IMAGE
            // ======================================================

            _productImage(imageUrl),

            const SizedBox(width: 15),

            // ======================================================
            // PRODUCT DETAILS
            // ======================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    fishName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'By $exporterName',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          Color(0xff0A4D68),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '₹${price.toStringAsFixed(2)} / kg',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xff0A4D68),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Quantity: $quantity kg',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Total: ₹${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // DELETE BUTTON
            // ======================================================

            IconButton(
              tooltip: 'Remove',
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: isRemoving
                  ? null
                  : () {
                      _removeFromCart(
                        document.id,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PRODUCT IMAGE
  // ================================================================

  Widget _productImage(
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xffE8F4F8),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.set_meal,
          size: 45,
          color: Color(0xff0A4D68),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 85,
        height: 85,
        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color:
                  const Color(0xffE8F4F8),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.set_meal,
              size: 45,
              color:
                  Color(0xff0A4D68),
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // BOTTOM SUMMARY
  // ================================================================

  Widget _bottomSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        items,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        15,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xff0A4D68),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff0A4D68),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _goToCheckout(items);
                },
                icon: const Icon(
                  Icons.shopping_cart_checkout,
                ),
                label: const Text(
                  'PROCEED TO CHECKOUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CONVERSION HELPERS
  // ================================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}