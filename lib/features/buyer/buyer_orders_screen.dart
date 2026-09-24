import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/category_helper.dart';
import '../../widgets/report_complaint_dialog.dart';

class BuyerOrdersScreen extends StatefulWidget {
  final VoidCallback? onBrowse;

  const BuyerOrdersScreen({super.key, this.onBrowse});

  // ================================================================
  // STATIC HELPER TO SHOW ORDER DETAILS FROM ANY SCREEN (E.G. HOME)
  // ================================================================
  static void showOrderDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String documentId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailsModal(
        data: data,
        documentId: documentId,
      ),
    );
  }

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  String _selectedFilter = 'All'; // 'All', 'Active', 'Completed'
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _getOrders();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getOrders() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff0A4D68)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load orders.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allOrders = snapshot.data?.docs ?? [];
          if (allOrders.isEmpty) {
            return _emptyOrders(context);
          }

          // Separate active vs completed
          final completedOrders = allOrders.where((doc) {
            final data = doc.data();
            final st = (data['status'] ?? '').toString().toLowerCase();
            final ship = (data['shipmentStatus'] ?? '').toString().toLowerCase();
            return st == 'completed' || st == 'delivered' || ship == 'delivered';
          }).toList();

          final activeOrders = allOrders.where((doc) {
            final data = doc.data();
            final st = (data['status'] ?? '').toString().toLowerCase();
            final ship = (data['shipmentStatus'] ?? '').toString().toLowerCase();
            final isCompleted = st == 'completed' || st == 'delivered' || ship == 'delivered';
            final isCancelled = st == 'cancelled' || st == 'rejected';
            return !isCompleted && !isCancelled;
          }).toList();

          // Apply Filter
          List<QueryDocumentSnapshot<Map<String, dynamic>>> displayedOrders;
          if (_selectedFilter == 'Active') {
            displayedOrders = activeOrders;
          } else if (_selectedFilter == 'Completed') {
            displayedOrders = completedOrders;
          } else {
            displayedOrders = allOrders;
          }

          return Column(
            children: [
              // Filter Chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _filterChip('All', allOrders.length),
                    const SizedBox(width: 8),
                    _filterChip('Active', activeOrders.length),
                    const SizedBox(width: 8),
                    _filterChip('Completed', completedOrders.length),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Orders List
              Expanded(
                child: displayedOrders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(
                            'No $_selectedFilter orders found.',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedOrders.length +
                            ((_selectedFilter == 'All' || _selectedFilter == 'Completed') &&
                                    completedOrders.isNotEmpty
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          // Show Recent Completed Order Spotlight at the very top
                          if ((_selectedFilter == 'All' || _selectedFilter == 'Completed') &&
                              completedOrders.isNotEmpty) {
                            if (index == 0) {
                              return _recentCompletedSpotlight(
                                context,
                                completedOrders.first,
                              );
                            }
                            return _orderCard(context, displayedOrders[index - 1]);
                          }

                          return _orderCard(context, displayedOrders[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String title, int count) {
    final bool isSelected = _selectedFilter == title;
    return ChoiceChip(
      label: Text('$title ($count)'),
      selected: isSelected,
      selectedColor: const Color(0xff0A4D68),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xff0A4D68),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = title);
        }
      },
    );
  }

  // ================================================================
  // RECENT COMPLETED ORDER SPOTLIGHT BANNER
  // ================================================================
  Widget _recentCompletedSpotlight(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final String orderId = data['orderId']?.toString() ?? document.id;
    final String fishName = data['fishName']?.toString() ?? 'Seafood Order';
    final double total = _toDouble(data['totalAmount']);
    final String paymentMethod = data['paymentMethod']?.toString() ?? 'Paid';
    final String date = _formatDate(data['createdAt']);
    final dynamic rawItems = data['items'] ?? data['products'] ?? [];
    int itemCount = rawItems is List ? rawItems.length : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4D68), Color(0xFF088395)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D68).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => BuyerOrdersScreen.showOrderDetails(context, data, document.id),
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
                        color: Colors.greenAccent.shade400.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.shade400, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
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
                    Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                              fontSize: 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$itemCount product${itemCount > 1 ? 's' : ''} • $paymentMethod',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TOTAL', style: TextStyle(color: Colors.white60, fontSize: 10)),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const Row(
                      children: [
                        Text(
                          'View Full Receipt',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
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
  }

  // ================================================================
  // ORDER CARD
  // ================================================================
  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final String orderId = data['orderId']?.toString() ?? document.id;
    final String status = data['status']?.toString() ?? 'Pending';
    final String shipmentStatus = data['shipmentStatus']?.toString() ?? 'Not Shipped';
    final double totalAmount = _toDouble(data['totalAmount']);
    final String paymentMethod = data['paymentMethod']?.toString() ?? 'Not specified';
    final String createdAt = _formatDate(data['createdAt']);
    final List<dynamic> items = data['items'] is List
        ? data['items'] as List
        : (data['products'] is List ? data['products'] as List : []);

    final Color statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => BuyerOrdersScreen.showOrderDetails(context, data, document.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.list_alt_rounded, color: Color(0xff0A4D68)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order ID', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(
                          orderId.length > 14 ? '${orderId.substring(0, 14)}...' : orderId,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Status and Shipment badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status), size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (shipmentStatus != 'Not Shipped') ...[
                        const SizedBox(height: 4),
                        _shipmentBadge(shipmentStatus),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Info Row
              Row(
                children: [
                  Expanded(
                    child: _infoItem(Icons.calendar_today_rounded, 'Date', createdAt),
                  ),
                  Expanded(
                    child: _infoItem(Icons.shopping_bag_rounded, 'Items', '${items.length} items'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _infoItem(Icons.payment_rounded, 'Payment', paymentMethod),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.currency_rupee_rounded,
                      'Total',
                      '₹${totalAmount.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff0A4D68),
                    side: const BorderSide(color: Color(0xff0A4D68)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => BuyerOrdersScreen.showOrderDetails(context, data, document.id),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('VIEW ORDER DETAILS & TRACKING'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shipmentBadge(String ship) {
    Color color;
    IconData icon;
    final lower = ship.toLowerCase();
    if (lower == 'delivered') {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (lower == 'shipped' || lower == 'in transit') {
      color = Colors.indigo;
      icon = Icons.local_shipping_rounded;
    } else {
      color = Colors.orange;
      icon = Icons.inventory_2_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            ship,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xff0A4D68)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyOrders(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xffE8F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.list_alt_rounded, size: 75, color: Color(0xff0A4D68)),
            ),
            const SizedBox(height: 25),
            const Text('No Orders Yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Your placed seafood orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4D68),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              ),
              onPressed: () {
                if (widget.onBrowse != null) {
                  widget.onBrowse!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.shopping_bag_rounded),
              label: const Text('SHOP NOW'),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'processing':
        return Colors.deepPurple;
      case 'shipped':
      case 'in transit':
        return Colors.indigo;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.inventory_2_rounded;
      case 'shipped':
      case 'in transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

String _formatDate(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final DateTime date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  return 'Recently';
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 1;
}


// ================================================================
// ORDER DETAILS MODAL SHEET
// ================================================================
class _OrderDetailsModal extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;

  const _OrderDetailsModal({required this.data, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final String orderId = data['orderId']?.toString() ?? documentId;
    final String status = data['status']?.toString() ?? 'Pending';
    final String shipmentStatus = data['shipmentStatus']?.toString() ?? 'Not Shipped';
    final double totalAmount = _toDouble(data['totalAmount']);
    final String paymentMethod = data['paymentMethod']?.toString() ?? 'Not specified';
    final String paymentStatus = data['paymentStatus']?.toString() ?? 'Pending';
    final String paymentId = data['paymentId']?.toString() ?? '';
    final String address = data['deliveryAddress']?.toString() ??
        data['address']?.toString() ??
        'Address not available';

    final List<dynamic> items = data['items'] is List
        ? data['items'] as List
        : (data['products'] is List ? data['products'] as List : []);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order & Tracking Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Order #${orderId.length > 12 ? orderId.substring(0, 12) : orderId}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5-STAGE STATUS TIMELINE & LIVE TRACKING
                    _statusTimeline(status, shipmentStatus),

                    const SizedBox(height: 24),

                    // DELIVERY ADDRESS
                    const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xff0A4D68)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(address, style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ORDER ITEMS
                    const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('No item details available.', style: TextStyle(color: Colors.grey))
                    else
                      ...items.map((item) {
                        if (item is! Map) return const SizedBox();
                        final String name = item['fishName']?.toString() ?? item['name']?.toString() ?? 'Product';
                        final int quantity = _toInt(item['quantity']);
                        final double price = _toDouble(item['price']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xffE8F4F8),
                                backgroundImage: AssetImage(
                                  CategoryHelper.getCategoryAssetImage(
                                    CategoryHelper.determineCategory(fishName: name),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$quantity kg × ₹${price.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // PAYMENT DETAILS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Method', style: TextStyle(color: Colors.black87)),
                              Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Status', style: TextStyle(color: Colors.black87)),
                              Text(
                                paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: paymentStatus.toLowerCase() == 'paid'
                                      ? Colors.green
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          if (paymentId.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(paymentId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                          ],
                          if (data['deliveryCharge'] != null && (data['deliveryCharge'] as num) > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items Subtotal', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('₹${((data['subtotal'] as num?)?.toDouble() ?? (totalAmount - (data['deliveryCharge'] as num).toDouble())).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cold-Chain Delivery (${(data['distanceKm'] as num?)?.toStringAsFixed(0) ?? '0'} km)', style: const TextStyle(color: Colors.teal, fontSize: 13)),
                                Text('₹${(data['deliveryCharge'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff0A4D68),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // REPORT GRIEVANCE / CHEATING TO ADMIN
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.report_problem_outlined, size: 18),
                        label: const Text('Report Issue / Cheating to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          final primaryFish = items.isNotEmpty ? items.first['fishName']?.toString() : null;
                          ReportComplaintDialog.show(
                            context,
                            orderId: orderId,
                            fishName: primaryFish,
                            accusedId: data['exporterId']?.toString(),
                            accusedName: data['exporterName']?.toString() ?? 'Exporter',
                            accusedRole: 'Exporter',
                            userRole: 'Buyer',
                          );
                        },
                      ),
                    ),

                    // CANCEL BUTTON (IF PENDING)
                    if (status.toLowerCase() == 'pending') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _cancelOrder(context, documentId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // 5-STAGE STATUS TIMELINE & LIVE SHIPMENT TRACKING
  // ================================================================
  Widget _statusTimeline(String orderStatus, String shipmentStatus) {
    final s = orderStatus.toLowerCase();
    final ship = shipmentStatus.toLowerCase();

    // Check for cancelled/rejected
    if (s == 'cancelled' || s == 'rejected') {
      final isCancelled = s == 'cancelled';
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(isCancelled ? Icons.cancel_rounded : Icons.block_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCancelled ? 'Order Cancelled' : 'Order Rejected by Exporter',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCancelled
                        ? 'This order was cancelled and is no longer being processed.'
                        : 'The exporter was unable to fulfill this consignment.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    const List<String> stages = ['Pending', 'Accepted', 'Processing', 'Shipped', 'Delivered'];
    int currentIndex = 0;
    if (s == 'delivered' || s == 'completed' || ship == 'delivered') {
      currentIndex = 4;
    } else if (s == 'shipped' || s == 'in transit' || ship == 'shipped' || ship == 'in transit') {
      currentIndex = 3;
    } else if (s == 'processing' || ship == 'preparing') {
      currentIndex = 2;
    } else if (s == 'accepted') {
      currentIndex = 1;
    } else {
      currentIndex = 0;
    }

    String trackingTitle;
    String trackingDesc;
    IconData trackingIcon;
    Color trackingColor;

    switch (currentIndex) {
      case 0:
        trackingTitle = 'Awaiting Exporter Confirmation';
        trackingDesc = 'Your seafood order has been placed and is waiting for exporter acceptance.';
        trackingIcon = Icons.hourglass_top_rounded;
        trackingColor = Colors.orange;
        break;
      case 1:
        trackingTitle = 'Order Accepted by Exporter';
        trackingDesc = 'The exporter accepted your consignment. Cold-chain preparation will begin.';
        trackingIcon = Icons.check_circle_rounded;
        trackingColor = Colors.blue;
        break;
      case 2:
        trackingTitle = 'Processing & Cold-Chain Packing';
        trackingDesc = 'Fish product is being cleaned, weighed, cold-chain packaged and prepared for shipping.';
        trackingIcon = Icons.inventory_2_rounded;
        trackingColor = Colors.deepPurple;
        break;
      case 3:
        trackingTitle = ship == 'in transit' ? 'Consignment In Transit 🌊' : 'Dispatched & Shipped Out 🚢';
        trackingDesc = ship == 'in transit'
            ? 'Your seafood cargo is currently in transit to your delivery destination.'
            : 'Your consignment has departed from the marine port and is on its way.';
        trackingIcon = Icons.local_shipping_rounded;
        trackingColor = Colors.indigo;
        break;
      case 4:
        trackingTitle = 'Delivered Successfully 🎉';
        trackingDesc = 'Your seafood consignment was delivered to your address. Thank you!';
        trackingIcon = Icons.verified_rounded;
        trackingColor = Colors.green;
        break;
      default:
        trackingTitle = 'Order Processing';
        trackingDesc = 'Your order is currently moving through the fulfillment stages.';
        trackingIcon = Icons.info_outline;
        trackingColor = const Color(0xff0A4D68);
    }

    return Column(
      children: [
        // 5-STAGE PROGRESS BAR
        Row(
          children: List.generate(stages.length, (index) {
            final bool completed = index <= currentIndex;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? const Color(0xff0A4D68) : Colors.grey.shade300,
                      boxShadow: completed
                          ? [
                              BoxShadow(
                                color: const Color(0xff0A4D68).withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      index == 0
                          ? Icons.access_time_rounded
                          : index == 1
                              ? Icons.check_rounded
                              : index == 2
                                  ? Icons.inventory_2_rounded
                                  : index == 3
                                      ? Icons.local_shipping_rounded
                                      : Icons.done_all_rounded,
                      size: 16,
                      color: completed ? Colors.white : Colors.grey,
                    ),
                  ),
                  if (index != stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 3.5,
                        color: index < currentIndex ? const Color(0xff0A4D68) : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((st) {
            final isCurrent = stages.indexOf(st) == currentIndex;
            return SizedBox(
              width: 58,
              child: Text(
                st,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? const Color(0xff0A4D68) : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // LIVE TRACKING STATUS BANNER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: trackingColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: trackingColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: trackingColor.withValues(alpha: 0.15),
                child: Icon(trackingIcon, color: trackingColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackingTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: trackingColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trackingDesc,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
        final orderData = orderDoc.data();

        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'Cancelled',
          'orderStatus': 'Cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Notify Buyer and Exporter(s)
        try {
          if (orderData != null) {
            final notifService = NotificationService();
            final buyerId = orderData['buyerId']?.toString() ?? FirebaseAuth.instance.currentUser?.uid ?? '';
            final buyerName = orderData['buyerName']?.toString() ?? 'Buyer';
            final fishName = orderData['fishName']?.toString() ?? 'seafood order';
            final primaryExporterId = orderData['exporterId']?.toString() ?? '';
            final dynamic rawExpIds = orderData['exporterIds'];
            final Set<String> exporterIds = {};
            if (rawExpIds is List) {
              for (final id in rawExpIds) {
                if (id != null && id.toString().isNotEmpty) {
                  exporterIds.add(id.toString());
                }
              }
            }
            if (primaryExporterId.isNotEmpty) exporterIds.add(primaryExporterId);

            if (buyerId.isNotEmpty) {
              await notifService.notifyUser(
                userId: buyerId,
                title: 'Order Cancelled',
                message: 'Your order for $fishName was successfully cancelled.',
                type: 'order_cancelled',
                orderId: orderId,
              );
            }

            for (final expId in exporterIds) {
              await notifService.notifyUser(
                userId: expId,
                title: 'Order Cancelled by Buyer ⚠️',
                message: '$buyerName has cancelled the order for $fishName.',
                type: 'order_cancelled',
                orderId: orderId,
              );
            }
          }
        } catch (notifErr) {
          debugPrint('Error sending cancellation notification: $notifErr');
        }

        if (context.mounted) {
          Navigator.pop(context); // close modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}