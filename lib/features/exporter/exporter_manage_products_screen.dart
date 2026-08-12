import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() =>
      _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getProducts() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('products')
        .where('exporterId', isEqualTo: user.uid)
        .snapshots();
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  void confirmDelete(
    String productId,
    String fishName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text(
            'Are you sure you want to delete "$fishName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await deleteProduct(productId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TOGGLE PRODUCT AVAILABILITY
  // ============================================================

  Future<void> toggleAvailability(
    String productId,
    bool currentStatus,
  ) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'isAvailable': !currentStatus,
        'status': !currentStatus ? 'Available' : 'Unavailable',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? 'Product marked as available'
                : 'Product marked as unavailable',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EDIT PRODUCT
  // ============================================================

  void showEditProductDialog(
    String productId,
    Map<String, dynamic> data,
  ) {
    final TextEditingController fishNameController =
        TextEditingController(
      text: data['fishName']?.toString() ?? '',
    );

    final TextEditingController priceController =
        TextEditingController(
      text: data['price']?.toString() ?? '',
    );

    final TextEditingController quantityController =
        TextEditingController(
      text: data['quantity']?.toString() ?? '',
    );

    final TextEditingController descriptionController =
        TextEditingController(
      text: data['description']?.toString() ?? '',
    );

    final TextEditingController locationController =
        TextEditingController(
      text: data['location']?.toString() ?? '',
    );

    String? selectedQuality =
        data['quality']?.toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Fish Product',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0A4D68),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: fishNameController,
                      decoration: const InputDecoration(
                        labelText: 'Fish Name',
                        prefixIcon: Icon(Icons.set_meal),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon:
                            Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedQuality,
                      decoration: const InputDecoration(
                        labelText: 'Quality',
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Premium',
                          child: Text('Premium'),
                        ),
                        DropdownMenuItem(
                          value: 'Grade A',
                          child: Text('Grade A'),
                        ),
                        DropdownMenuItem(
                          value: 'Grade B',
                          child: Text('Grade B'),
                        ),
                        DropdownMenuItem(
                          value: 'Standard',
                          child: Text('Standard'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedQuality = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon:
                            Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon:
                            Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String fishName =
                        fishNameController.text.trim();

                    final double? price =
                        double.tryParse(
                      priceController.text.trim(),
                    );

                    final double? quantity =
                        double.tryParse(
                      quantityController.text.trim(),
                    );

                    if (fishName.isEmpty ||
                        price == null ||
                        quantity == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid product details',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _firestore
                          .collection('products')
                          .doc(productId)
                          .update({
                        'fishName': fishName,
                        'price': price,
                        'quantity': quantity,
                        'quality': selectedQuality,
                        'location':
                            locationController.text.trim(),
                        'description':
                            descriptionController.text.trim(),
                        'updatedAt': Timestamp.now(),
                      });

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Product updated successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Update failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff0A4D68),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      appBar: AppBar(
        title: const Text('My Fish Products'),
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getProducts(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading products:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,

            itemBuilder: (context, index) {
              final document = products[index];

              return _buildProductCard(
                document.id,
                document.data(),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.set_meal,
              size: 90,
              color: Color(0xff0A4D68),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Fish Products',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'You have not added any fish products yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Fish'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff0A4D68),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    String productId,
    Map<String, dynamic> data,
  ) {
    final String fishName =
        data['fishName']?.toString() ?? 'Unknown Fish';

    final String fishType =
        data['fishType']?.toString() ?? 'Unknown Type';

    final String quality =
        data['quality']?.toString() ?? 'Standard';

    final String description =
        data['description']?.toString() ?? '';

    final String location =
        data['location']?.toString() ?? 'Not specified';

    final dynamic price = data['price'] ?? 0;

    final dynamic quantity =
        data['quantity'] ?? 0;

    final String unit =
        data['unit']?.toString() ?? 'Kg';

    final bool isAvailable =
        data['isAvailable'] ??
            (data['status']?.toString() != 'Unavailable');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // PRODUCT HEADER
            // ----------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: const Color(0xffE3F2F7),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.set_meal,
                    size: 48,
                    color: Color(0xff0A4D68),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        fishName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0A4D68),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        fishType,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '₹$price / $unit',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Stock: $quantity $unit',
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.green
                              : Colors.red,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // QUALITY + STATUS
            // ----------------------------------------------------

            Row(
              children: [
                _infoChip(
                  Icons.star,
                  quality,
                  Colors.orange,
                ),

                const SizedBox(width: 8),

                _infoChip(
                  isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  isAvailable
                      ? 'Available'
                      : 'Unavailable',
                  isAvailable
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // LOCATION
            // ----------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Color(0xff0A4D68),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------

            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),

              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 12),

            const Divider(),

            // ----------------------------------------------------
            // ACTIONS
            // ----------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showEditProductDialog(
                      productId,
                      data,
                    );
                  },
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                  ),
                  label: const Text('Edit'),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    toggleAvailability(
                      productId,
                      isAvailable,
                    );
                  },
                  icon: Icon(
                    isAvailable
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(
                    isAvailable
                        ? 'Hide'
                        : 'Show',
                  ),
                ),

                IconButton(
                  onPressed: () {
                    confirmDelete(
                      productId,
                      fishName,
                    );
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION CHIP
  // ============================================================

  Widget _infoChip(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}