import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/category_helper.dart';
import '../../utils/stock_helper.dart';
import 'buyer_orders_screen.dart';
import 'buyer_product_details_screen.dart';


class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final ProductService productService = ProductService();
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  String searchText = '';
  String buyerName = 'Buyer';

  static const Color primaryColor = Color(0xff0A4D68);
  static const Color lightBlue = Color(0xffE8F4F8);

  late Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _recentOrdersStream;

  @override
  void initState() {
    super.initState();
    _productsStream = productService.getProducts();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _recentOrdersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .snapshots();
    }
    _loadBuyerName();
  }

  // ================================================================
  // LOAD BUYER NAME
  // ================================================================

  Future<void> _loadBuyerName() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) {
        return;
      }

      if (doc.exists && doc.data() != null) {
        final dynamic nameValue = doc.data()!['name'];

        if (nameValue != null) {
          final String name = nameValue.toString().trim();

          if (name.isNotEmpty) {
            setState(() {
              buyerName = name;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Unable to load buyer name: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F7FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorView(
                'Unable to load products.\nPlease try again later.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            final List<Product> products = [];

            for (final document in snapshot.data?.docs ?? []) {
              try {
                final Product product = Product.fromMap(
                  document.data(),
                  document.id,
                );

                products.add(product);
              } catch (e) {
                debugPrint(
                  'Unable to convert product ${document.id}: $e',
                );
              }
            }

            final List<Product> filteredProducts =
                products.where(_matchesFilters).toList();

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                setState(() {
                  _productsStream = productService.getProducts();
                });
                await Future.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeCard(),

                    _recentCompletedOrderCard(),

                    const SizedBox(height: 20),

                    _searchBar(),

                    const SizedBox(height: 25),

                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _categories(),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedCategory == 'All'
                                ? 'Available Products'
                                : '$selectedCategory Products',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${filteredProducts.length} '
                          'item${filteredProducts.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (filteredProducts.isEmpty)
                      _emptyProductsView()
                    else
                      _productGrid(filteredProducts),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // WELCOME CARD
  // ================================================================

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF061A28),
            Color(0xFF0A4D68),
            Color(0xFF088395),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D68).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF05BFDB), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified Export Market',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome back, $buyerName 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Direct port-to-door fresh seafood marketplace.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CategoryHelper.buildProductIcon(
                category: 'All',
                size: 64,
                isCircle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Perk Badges Row
          Row(
            children: [
              _buildPerkPill('❄️ Cold Chain', Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 8),
              _buildPerkPill('⚡ Fast Dispatch', Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 8),
              _buildPerkPill('💳 Razorpay', Colors.white.withValues(alpha: 0.15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerkPill(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================================================================
  // RECENT COMPLETED ORDER BANNER
  // ================================================================
  Widget _recentCompletedOrderCard() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recentOrdersStream ??
          FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final completed = docs.where((d) {
          final data = d.data();
          final st = (data['status'] ?? '').toString().toLowerCase();
          final ship = (data['shipmentStatus'] ?? '').toString().toLowerCase();
          return st == 'completed' || st == 'delivered' || ship == 'delivered';
        }).toList();

        if (completed.isEmpty) return const SizedBox.shrink();

        // Sort by createdAt descending
        completed.sort((a, b) {
          final ta = a.data()['createdAt'];
          final tb = b.data()['createdAt'];
          if (ta is Timestamp && tb is Timestamp) {
            return tb.compareTo(ta);
          }
          return 0;
        });

        final latest = completed.first;
        final data = latest.data();
        final String orderId = data['orderId']?.toString() ?? latest.id;
        final String fishName = data['fishName']?.toString() ?? 'Seafood Order';
        final double total = (data['totalAmount'] is num)
            ? (data['totalAmount'] as num).toDouble()
            : (double.tryParse(data['totalAmount']?.toString() ?? '') ?? 0.0);
        final String paymentMethod = data['paymentMethod']?.toString() ?? 'Paid';
        final dynamic rawItems = data['items'] ?? data['products'] ?? [];
        final int itemCount = rawItems is List ? rawItems.length : 1;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF061A28), Color(0xFF0A4D68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0A4D68).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => BuyerOrdersScreen.showOrderDetails(context, data, latest.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.shade400, width: 1.2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'RECENT COMPLETED ORDER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'DELIVERED',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fishName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$itemCount item${itemCount > 1 ? 's' : ''} • $paymentMethod',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PAID', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Tracking & Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // SEARCH BAR
  // ================================================================

  Widget _searchBar() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchText = value;
        });
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search fish, category or exporter...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: primaryColor,
        ),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchText = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CATEGORIES
  // ================================================================

  Widget _categories() {
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _category(
            title: 'All',
            category: 'All',
          ),
          _category(
            title: 'Fish',
            category: 'Fish',
          ),
          _category(
            title: 'Prawns',
            category: 'Prawns',
          ),
          _category(
            title: 'Crab',
            category: 'Crab',
          ),
          _category(
            title: 'Others',
            category: 'Others',
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CATEGORY BUTTON
  // ================================================================

  Widget _category({
    required String title,
    required String category,
  }) {
    final bool selected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xff0A4D68) : Colors.grey.shade300,
                  width: selected ? 3.0 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xff0A4D68).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      CategoryHelper.getCategoryAssetImage(category),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: CategoryHelper.getCategoryLightColor(category),
                        child: Center(
                          child: Text(
                            CategoryHelper.getCategoryEmoji(category),
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay to enhance contrast and selection
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: selected
                              ? [
                                  const Color(0xff0A4D68).withValues(alpha: 0.15),
                                  const Color(0xff0A4D68).withValues(alpha: 0.55),
                                ]
                              : [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                ],
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xff00D26A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? const Color(0xff0A4D68) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FILTER
  // ================================================================

  bool _matchesFilters(Product product) {
    // Do not show products without stock.
    if (product.quantity <= 0 || product.isOutOfStock) {
      return false;
    }


    // Search filter.
    final String search = searchText.trim().toLowerCase();

    if (search.isNotEmpty) {
      final String fishName =
          product.fishName.trim().toLowerCase();

      final String category =
          product.category.trim().toLowerCase();

      final String exporter =
          product.exporterName.trim().toLowerCase();

      final String description =
          product.description.trim().toLowerCase();

      final bool matchesSearch =
          fishName.contains(search) ||
          category.contains(search) ||
          exporter.contains(search) ||
          description.contains(search);

      if (!matchesSearch) {
        return false;
      }
    }

    // Category filter.
    if (selectedCategory != 'All') {
      final String productCategory =
          _normalizeCategory(product.category);

      final String selected =
          _normalizeCategory(selectedCategory);

      if (productCategory != selected) {
        return false;
      }
    }

    return true;
  }

  // ================================================================
  // CATEGORY NORMALIZATION
  // ================================================================

  String _normalizeCategory(String category) {
    String value = category
        .trim()
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');

    value = value.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (value.contains('prawn') ||
        value.contains('shrimp')) {
      return 'prawns';
    }

    if (value.contains('crab')) {
      return 'crab';
    }

    if (value.contains('fish')) {
      return 'fish';
    }

    if (value.contains('other') ||
        value.contains('seafood') ||
        value.contains('shellfish')) {
      return 'others';
    }

    if (value.endsWith('s') && value.length > 1) {
      value = value.substring(
        0,
        value.length - 1,
      );
    }

    return value;
  }

  // ================================================================
  // PRODUCT GRID
  // ================================================================

  Widget _productGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        return _productCard(products[index]);
      },
    );
  }

  // ================================================================
  // PRODUCT CARD
  // ================================================================

  Widget _productCard(Product product) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _openProduct(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _productImage(product.imageUrl, category: product.category),
              ),
            ),

            // DETAILS
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                9,
                10,
                8,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.fishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  _categoryBadge(product.category),

                  const SizedBox(height: 6),

                  Text(
                    '₹${product.price.toStringAsFixed(2)} / kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          StockHelper.formatStockDetailed(product.quantity),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        _openProduct(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CATEGORY BADGE
  // ================================================================

  Widget _categoryBadge(String category) {
    final Color color = CategoryHelper.getCategoryColor(category);
    final Color background = CategoryHelper.getCategoryLightColor(category);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 130,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CategoryHelper.getCategoryEmoji(category),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // OPEN PRODUCT
  // ================================================================

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerProductDetailsScreen(
          product: product,
        ),
      ),
    );
  }

  // ================================================================
  // PRODUCT IMAGE
  // ================================================================

  Widget _productImage(String imageUrl, {String category = 'Fish'}) {
    if (imageUrl.trim().isEmpty) {
      return _imagePlaceholder(category: category);
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder:
          (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _imageLoading();
      },
      errorBuilder:
          (context, error, stackTrace) {
        return _imagePlaceholder(category: category);
      },
    );
  }

  // ================================================================
  // IMAGE PLACEHOLDER
  // ================================================================

  Widget _imagePlaceholder({String category = 'Fish'}) {
    return Image.asset(
      CategoryHelper.getCategoryAssetImage(category),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Container(
        width: double.infinity,
        height: double.infinity,
        color: lightBlue,
        child: const Center(
          child: Text(
            '🐟',
            style: TextStyle(fontSize: 50),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // IMAGE LOADING
  // ================================================================

  Widget _imageLoading() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: lightBlue,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryColor,
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY PRODUCTS
  // ================================================================

  Widget _emptyProductsView() {
    String message;

    if (selectedCategory == 'All' &&
        searchText.trim().isEmpty) {
      message =
          'No seafood products are available right now.';
    } else if (searchText.trim().isNotEmpty) {
      message =
          'No products found for "$searchText".';
    } else {
      message =
          'No products found in the '
          '$selectedCategory category.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 70,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          if (selectedCategory != 'All')
            OutlinedButton(
              onPressed: () {
                setState(() {
                  selectedCategory = 'All';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(
                  color: primaryColor,
                ),
              ),
              child: const Text(
                'View All Products',
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR VIEW
  // ================================================================

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 65,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}