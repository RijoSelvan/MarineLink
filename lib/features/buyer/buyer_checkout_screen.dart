import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/product_service.dart';

class BuyerCheckoutScreen extends StatefulWidget {
  const BuyerCheckoutScreen({super.key});

  @override
  State<BuyerCheckoutScreen> createState() =>
      _BuyerCheckoutScreenState();
}

class _BuyerCheckoutScreenState
    extends State<BuyerCheckoutScreen> {
  final ProductService productService = ProductService();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController pincodeController =
      TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _loadBuyerDetails();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    pincodeController.dispose();

    super.dispose();
  }

  // ================================================================
  // LOAD BUYER DETAILS
  // ================================================================

  Future<void> _loadBuyerDetails() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final document = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!document.exists) return;

      final data = document.data();

      if (data == null) return;

      if (!mounted) return;

      setState(() {
        nameController.text =
            data['name']?.toString() ?? '';

        phoneController.text =
            data['phone']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint(
        'Error loading buyer details: $e',
      );
    }
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
          'Checkout',
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: productService.getCart(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff0A4D68),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load cart.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final items =
              snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          double total = 0;

          for (final item in items) {
            final data = item.data();

            final double price =
                _toDouble(data['price']);

            final int quantity =
                _toInt(data['quantity']);

            total += price * quantity;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // ORDER SUMMARY
                // ==================================================

                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ...items.map(
                  (document) {
                    final data =
                        document.data();

                    final String fishName =
                        data['fishName']
                                ?.toString() ??
                            'Product';

                    final double price =
                        _toDouble(
                      data['price'],
                    );

                    final int quantity =
                        _toInt(
                      data['quantity'],
                    );

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          backgroundColor:
                              Color(0xffE8F4F8),
                          child: Icon(
                            Icons.set_meal,
                            color:
                                Color(0xff0A4D68),
                          ),
                        ),
                        title: Text(
                          fishName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$quantity kg × ₹${price.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          '₹${(price * quantity).toStringAsFixed(2)}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xff0A4D68),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // DELIVERY DETAILS
                // ==================================================

                const Text(
                  'Delivery Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _textField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),

                const SizedBox(height: 15),

                _textField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 15),

                _textField(
                  controller:
                      addressController,
                  label: 'Delivery Address',
                  icon: Icons.home,
                  maxLines: 3,
                ),

                const SizedBox(height: 15),

                _textField(
                  controller: cityController,
                  label: 'City',
                  icon: Icons.location_city,
                ),

                const SizedBox(height: 15),

                _textField(
                  controller:
                      pincodeController,
                  label: 'PIN Code',
                  icon: Icons.pin_drop,
                  keyboardType:
                      TextInputType.number,
                ),

                const SizedBox(height: 25),

                // ==================================================
                // TOTAL
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xffE8F4F8),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 19,
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
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PAYMENT METHOD
                // ==================================================

                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.money,
                        color:
                            Color(0xff0A4D68),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // PLACE ORDER
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff0A4D68),
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            _placeOrder(
                              items,
                              total,
                            );
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'PLACE ORDER',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // PLACE ORDER
  // ================================================================

  Future<void> _placeOrder(
    List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        items,
    double total,
  ) async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all delivery details.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please login before placing an order.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final List<Map<String, dynamic>>
          products = [];

      for (final document in items) {
        final data = document.data();

        products.add({
          'productId':
              data['productId'] ?? document.id,
          'fishName':
              data['fishName'] ?? '',
          'category':
              data['category'] ?? '',
          'price':
              _toDouble(data['price']),
          'quantity':
              _toInt(data['quantity']),
          'imageUrl':
              data['imageUrl'] ?? '',
          'exporterId':
              data['exporterId'] ?? '',
          'exporterName':
              data['exporterName'] ?? '',
        });
      }

      // Create order
      final DocumentReference orderDocument =
          FirebaseFirestore.instance
              .collection('orders')
              .doc();

      await orderDocument.set({
        'orderId':
            orderDocument.id,

        'buyerId':
            user.uid,

        'buyerName':
            nameController.text.trim(),

        'buyerPhone':
            phoneController.text.trim(),

        'deliveryAddress':
            addressController.text.trim(),

        'city':
            cityController.text.trim(),

        'pincode':
            pincodeController.text.trim(),

        'products':
            products,

        'totalAmount':
            total,

        'paymentMethod':
            'Cash on Delivery',

        'paymentStatus':
            'Pending',

        'orderStatus':
            'Pending',

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      // Clear buyer cart
      final WriteBatch batch =
          FirebaseFirestore.instance.batch();

      for (final document in items) {
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(document.id),
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Success message
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Order placed successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to place order: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
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