import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/category_helper.dart';

class AdminManageProductsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminManageProductsScreen({super.key, this.isEmbedded = true});

  @override
  State<AdminManageProductsScreen> createState() => _AdminManageProductsScreenState();
}

class _AdminManageProductsScreenState extends State<AdminManageProductsScreen> {
  final Color primaryColor = const Color(0xff0A4D68);
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'All'; // 'All', 'In Stock', 'Out of Stock'

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // ==========================================================
        // SEARCH & FILTER BAR
        // ==========================================================
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by fish name or exporter...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xffF4F9FF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(label: 'All Categories', isSelected: _selectedCategory == 'All', onSelected: () => setState(() => _selectedCategory = 'All')),
                    const SizedBox(width: 8),
                    _filterChip(label: 'All Stock', isSelected: _stockFilter == 'All', onSelected: () => setState(() => _stockFilter = 'All')),
                    const SizedBox(width: 8),
                    _filterChip(label: 'In Stock', isSelected: _stockFilter == 'In Stock', onSelected: () => setState(() => _stockFilter = 'In Stock')),
                    const SizedBox(width: 8),
                    _filterChip(label: 'Out of Stock', isSelected: _stockFilter == 'Out of Stock', onSelected: () => setState(() => _stockFilter = 'Out of Stock')),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // ==========================================================
        // PRODUCTS STREAM LIST
        // ==========================================================
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Unable to load products', style: TextStyle(color: Colors.red)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              final allProducts = snapshot.data?.docs ?? [];

              // Filter products
              final filtered = allProducts.where((doc) {
                final product = doc.data();
                final name = (product['fishName'] ?? product['name'] ?? '').toString().toLowerCase();
                final exporter = (product['exporterName'] ?? '').toString().toLowerCase();
                final category = (product['category'] ?? '').toString().toLowerCase();
                final int quantity = _toInt(product['quantity']);
                final bool isAvailable = product['isAvailable'] == true && quantity > 0;

                // Category filter
                if (_selectedCategory != 'All' &&
                    !category.contains(_selectedCategory.toLowerCase())) {
                  return false;
                }

                // Stock filter
                if (_stockFilter == 'In Stock' && !isAvailable) {
                  return false;
                }
                if (_stockFilter == 'Out of Stock' && isAvailable) {
                  return false;
                }

                // Search query
                if (_searchQuery.isNotEmpty) {
                  final matchName = name.contains(_searchQuery);
                  final matchExp = exporter.contains(_searchQuery);
                  final matchCat = category.contains(_searchQuery);
                  if (!matchName && !matchExp && !matchCat) return false;
                }

                return true;
              }).toList();

              // Sort in memory (newest first or alphabetical)
              filtered.sort((a, b) {
                final aData = a.data();
                final bData = b.data();
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime != null && bTime != null) {
                  return bTime.compareTo(aTime);
                }
                final aName = (aData['fishName'] ?? '').toString();
                final bName = (bData['fishName'] ?? '').toString();
                return aName.compareTo(bName);
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No products found',
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchQuery.isNotEmpty ? 'Try changing your search terms.' : 'No seafood listed yet.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  await FirebaseFirestore.instance.collection('products').get();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return _buildProductCard(context, doc.id, doc.data());
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),
      appBar: AppBar(
        title: const Text('Manage Products', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  // ================================================================
  // FILTER CHIP
  // ================================================================
  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade300),
      onSelected: (_) => onSelected(),
    );
  }

  // ================================================================
  // PRODUCT CARD
  // ================================================================
  Widget _buildProductCard(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
  ) {
    final String name = product['fishName']?.toString() ?? product['name']?.toString() ?? 'Fish Product';
    final String category = product['category']?.toString() ?? 'General';
    final String exporter = product['exporterName']?.toString() ?? 'Exporter';
    final String imageUrl = product['imageUrl']?.toString() ?? '';
    final double price = _toDouble(product['price']);
    final int quantity = _toInt(product['quantity']);
    final bool isAvailable = product['isAvailable'] == true && quantity > 0;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _productImage(imageUrl, category: category),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAvailable ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                color: isAvailable ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exporter: $exporter',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(2)} / kg',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            '$quantity kg',
                            style: TextStyle(
                              color: isAvailable ? Colors.black87 : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick Toggle Stock Switch
                Text(
                  'Available: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isAvailable,
                    activeThumbColor: primaryColor,
                    onChanged: (val) => _toggleAvailability(productId, val, quantity),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showProductDetails(context, productId, product),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                  tooltip: 'Edit Product',
                  onPressed: () => _showEditProductDialog(context, productId, product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Delete Product',
                  onPressed: () => _confirmDelete(context, productId, name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TOGGLE AVAILABILITY
  // ================================================================
  Future<void> _toggleAvailability(String productId, bool newStatus, int currentQty) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'isAvailable': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================================================================
  // EDIT PRODUCT DIALOG
  // ================================================================
  void _showEditProductDialog(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
  ) {
    final nameCtrl = TextEditingController(text: product['fishName'] ?? product['name'] ?? '');
    final priceCtrl = TextEditingController(text: (product['price'] ?? '').toString());
    final qtyCtrl = TextEditingController(text: (product['quantity'] ?? '').toString());
    final descCtrl = TextEditingController(text: product['description'] ?? '');
    final catCtrl = TextEditingController(text: product['category'] ?? '');
    bool isAvailable = product['isAvailable'] == true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Seafood Product', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Fish / Product Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (₹/kg)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock (kg)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Mark Available in Catalog'),
                    contentPadding: EdgeInsets.zero,
                    value: isAvailable,
                    activeThumbColor: primaryColor,
                    onChanged: (val) => setDialogState(() => isAvailable = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final newPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                  final newQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;

                  Navigator.pop(dialogCtx);
                  try {
                    await FirebaseFirestore.instance.collection('products').doc(productId).update({
                      'fishName': nameCtrl.text.trim(),
                      'category': catCtrl.text.trim(),
                      'price': newPrice,
                      'quantity': newQty,
                      'description': descCtrl.text.trim(),
                      'isAvailable': isAvailable && newQty > 0,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update product: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // PRODUCT DETAILS MODAL
  // ================================================================
  void _showProductDetails(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
  ) {
    final String name = product['fishName'] ?? product['name'] ?? 'Unknown';
    final String category = product['category'] ?? 'General';
    final String description = product['description'] ?? 'No description provided.';
    final String exporter = product['exporterName'] ?? 'Unknown';
    final String exporterId = product['exporterId'] ?? 'N/A';
    final double price = _toDouble(product['price']);
    final int quantity = _toInt(product['quantity']);
    final String imageUrl = product['imageUrl'] ?? '';
    final bool isAvailable = product['isAvailable'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          CategoryHelper.getCategoryAssetImage(product['category']?.toString() ?? 'Fish'),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        CategoryHelper.getCategoryAssetImage(product['category']?.toString() ?? 'Fish'),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAvailable ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Category: $category',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price per kg', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Stock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$quantity kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: Colors.black87, height: 1.4)),
              const SizedBox(height: 14),
              const Divider(),
              Text('Exporter: $exporter', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Exporter ID: $exporterId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('Product ID: $productId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PRODUCT IMAGE
  // ================================================================
  Widget _productImage(String imageUrl, {String category = 'Fish'}) {
    final String fallbackAsset = CategoryHelper.getCategoryAssetImage(category);

    if (imageUrl.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          fallbackAsset,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xffE8F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.set_meal, size: 36, color: primaryColor),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              width: 80,
              height: 80,
              color: const Color(0xffE8F4F8),
              child: Icon(Icons.broken_image, color: primaryColor),
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // DELETE PRODUCT
  // ================================================================
  Future<void> _confirmDelete(
    BuildContext context,
    String productId,
    String productName,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}