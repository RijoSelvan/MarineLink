import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/category_helper.dart';
import '../../utils/stock_helper.dart';


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
  // OUT OF STOCK ACTION
  // ============================================================

  void confirmSetOutOfStock(
    String productId,
    String fishName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.remove_shopping_cart, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Mark Out of Stock?'),
            ],
          ),
          content: Text(
            'Are you sure you want to mark "$fishName" as Out of Stock?\n\n'
            'Buyers will not be able to order this product until you restock it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await setOutOfStock(productId, fishName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Out of Stock'),
            ),
          ],
        );
      },
    );
  }

  Future<void> setOutOfStock(String productId, String fishName) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isAvailable': false,
        'status': 'Out of Stock',
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$fishName" is now marked as Out of Stock'),
          backgroundColor: Colors.deepOrange,
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
  // RESTOCK DIALOG (1 box = 50 kg, 1 ton = 20 boxes = 1000 kg)
  // ============================================================

  void showRestockDialog(
    String productId,
    String fishName,
    int currentStock,
  ) {
    final TextEditingController addQtyController =
        TextEditingController(text: '1');
    int selectedUnitIndex = 0; // 0: Boxes (x50 kg), 1: Tons (x1000 kg), 2: Kg

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {

            final double enteredVal =
                double.tryParse(addQtyController.text.trim()) ?? 0;
            double effectiveAddKg = 0;
            if (selectedUnitIndex == 0) {
              // Boxes (1 box = 50 kg)
              effectiveAddKg = enteredVal * StockHelper.kgPerBox;
            } else if (selectedUnitIndex == 1) {
              // Tons (1 ton = 1000 kg = 20 boxes)
              effectiveAddKg = enteredVal * StockHelper.kgPerTon;
            } else {
              // Direct kg
              effectiveAddKg = enteredVal;
            }

            final int newTotalKg = (currentStock > 0 ? currentStock : 0) +
                effectiveAddKg.toInt();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.add_shopping_cart, color: Color(0xff0A4D68)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restock $fishName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Color(0xff0A4D68)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              StockHelper.unitReferenceNote,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff0A4D68),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Select Unit:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Boxes (50 kg)'),
                          selected: selectedUnitIndex == 0,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedUnitIndex = 0;
                                addQtyController.text = '1';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Tons (20 boxes)'),
                          selected: selectedUnitIndex == 1,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedUnitIndex = 1;
                                addQtyController.text = '1';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Kg'),
                          selected: selectedUnitIndex == 2,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedUnitIndex = 2;
                                addQtyController.text = '50';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addQtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: selectedUnitIndex == 0
                            ? 'Number of Boxes'
                            : selectedUnitIndex == 1
                                ? 'Number of Tons'
                                : 'Quantity in Kg',
                        prefixIcon: const Icon(Icons.scale),
                        border: const OutlineInputBorder(),
                        suffixText: selectedUnitIndex == 0
                            ? 'boxes'
                            : selectedUnitIndex == 1
                                ? 'tons'
                                : 'kg',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adding: ${effectiveAddKg.toInt()} kg (${effectiveAddKg ~/ 50} boxes • ${(effectiveAddKg / 1000).toStringAsFixed(2)} tons)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'New Total Stock: $newTotalKg kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: effectiveAddKg <= 0
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          try {
                            await _firestore
                                .collection('products')
                                .doc(productId)
                                .update({
                              'quantity': newTotalKg,
                              'isAvailable': true,
                              'status': 'Available',
                              'updatedAt': Timestamp.now(),
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"$fishName" restocked to $newTotalKg kg successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to restock: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4D68),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Restock'),
                ),
              ],
            );
          },
        );
      },
    );
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
                        labelText: 'Quantity (Kg)',
                        prefixIcon: Icon(Icons.scale),
                        helperText: '1 Box = 50 kg • 1 Ton = 20 Boxes (1,000 kg)',
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
                      final bool available = quantity > 0;
                      await _firestore
                          .collection('products')
                          .doc(productId)
                          .update({
                        'fishName': fishName,
                        'price': price,
                        'quantity': quantity.toInt(),
                        'quality': selectedQuality,
                        'isAvailable': available,
                        'status': available ? 'Available' : 'Out of Stock',
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

    final dynamic quantity = data['quantity'] ?? 0;
    final num qtyNum = (quantity is num)
        ? quantity
        : (num.tryParse(quantity.toString()) ?? 0);

    final String unit = data['unit']?.toString() ?? 'Kg';

    final String statusStr =
        data['status']?.toString().toLowerCase().trim() ?? '';
    final bool rawAvailable =
        data['isAvailable'] ?? (statusStr != 'unavailable');
    final bool isOutOfStock = !rawAvailable ||
        statusStr == 'out of stock' ||
        statusStr == 'unavailable' ||
        qtyNum <= 0;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryHelper.buildProductIcon(
                  category: data['category']?.toString() ?? 'Fish',
                  fishName: fishName,
                  size: 85,
                  borderRadius: 14,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOutOfStock
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  size: 14,
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.green.shade800,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isOutOfStock ? 'OUT OF STOCK' : 'IN STOCK',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.green.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOutOfStock
                                  ? '0 kg available'
                                  : StockHelper.formatStockDetailed(qtyNum),
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.red
                                    : Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (!isOutOfStock)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '📦 ${qtyNum ~/ 50} Boxes • ${(qtyNum / 1000).toStringAsFixed(qtyNum % 1000 == 0 ? 0 : 2)} Tons',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
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
                  !isOutOfStock ? Icons.check_circle : Icons.cancel,
                  !isOutOfStock ? 'Available' : 'Out of Stock',
                  !isOutOfStock ? Colors.green : Colors.red,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                    size: 16,
                  ),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),

                // Dedicated OUT OF STOCK / RESTOCK Button
                if (!isOutOfStock)
                  ElevatedButton.icon(
                    onPressed: () {
                      confirmSetOutOfStock(
                        productId,
                        fishName,
                      );
                    },
                    icon: const Icon(
                      Icons.block,
                      size: 16,
                    ),
                    label: const Text('Out of Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 1,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      showRestockDialog(
                        productId,
                        fishName,
                        qtyNum.toInt(),
                      );
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 16,
                    ),
                    label: const Text('Restock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A4D68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 1,
                    ),
                  ),

                OutlinedButton.icon(
                  onPressed: () {
                    toggleAvailability(
                      productId,
                      !isOutOfStock,
                    );
                  },
                  icon: Icon(
                    !isOutOfStock
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(
                    !isOutOfStock ? 'Hide' : 'Show',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete Product',
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