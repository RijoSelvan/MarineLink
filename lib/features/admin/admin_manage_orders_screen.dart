import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class AdminManageOrdersScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminManageOrdersScreen({super.key, this.isEmbedded = true});

  @override
  State<AdminManageOrdersScreen> createState() => _AdminManageOrdersScreenState();
}

class _AdminManageOrdersScreenState extends State<AdminManageOrdersScreen> {
  final Color primaryColor = const Color(0xff0A4D68);
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseFirestore.instance.collection('orders').snapshots();
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
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Order ID, Buyer name or phone...',
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

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('All'),
                    const SizedBox(width: 8),
                    _statusChip('Pending'),
                    const SizedBox(width: 8),
                    _statusChip('Confirmed'),
                    const SizedBox(width: 8),
                    _statusChip('Shipped'),
                    const SizedBox(width: 8),
                    _statusChip('Delivered'),
                    const SizedBox(width: 8),
                    _statusChip('Cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // ==========================================================
        // ORDERS STREAM LIST
        // ==========================================================
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ordersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Unable to load orders\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              final allOrders = snapshot.data?.docs ?? [];

              int totalOrders = allOrders.length;
              double totalSpend = 0.0;
              int completedCount = 0;
              int activeCount = 0;

              for (final doc in allOrders) {
                final data = doc.data();
                final st = (data['status'] ?? data['orderStatus'] ?? '').toString().toLowerCase();
                final amt = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                if (st != 'cancelled' && st != 'rejected') {
                  totalSpend += amt;
                }
                if (st == 'completed' || st == 'delivered') {
                  completedCount++;
                } else if (st != 'cancelled' && st != 'rejected') {
                  activeCount++;
                }
              }

              // Filter orders
              final filtered = allOrders.where((doc) {
                final order = doc.data();
                final orderId = (order['orderId'] ?? doc.id).toString().toLowerCase();
                final buyerName = (order['buyerName'] ?? '').toString().toLowerCase();
                final buyerPhone = (order['buyerPhone'] ?? '').toString().toLowerCase();
                final status = (order['status'] ?? order['orderStatus'] ?? 'pending').toString().toLowerCase();

                // Status filter
                if (_selectedStatusFilter != 'All' &&
                    status != _selectedStatusFilter.toLowerCase()) {
                  return false;
                }

                // Search query filter
                if (_searchQuery.isNotEmpty) {
                  final matchId = orderId.contains(_searchQuery);
                  final matchName = buyerName.contains(_searchQuery);
                  final matchPhone = buyerPhone.contains(_searchQuery);
                  if (!matchId && !matchName && !matchPhone) return false;
                }

                return true;
              }).toList();

              // Sort in memory by createdAt descending
              filtered.sort((a, b) {
                final aData = a.data();
                final bData = b.data();
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime != null && bTime != null) {
                  return bTime.compareTo(aTime);
                }
                return 0;
              });

              return Column(
                children: [
                  // Platform Orders & Amount Spent Statistics Banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF061A28), Color(0xFF0A4D68)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0A4D68).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 3),
                            Text('$totalOrders', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: Colors.white24),
                        Column(
                          children: [
                            const Text('Total Amount Spent', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 3),
                            Text('₹${totalSpend.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF05BFDB), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: Colors.white24),
                        Column(
                          children: [
                            const Text('Completed / Active', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 3),
                            Text('$completedCount / $activeCount', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text(
                                  'No orders found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedStatusFilter != 'All'
                                      ? 'Try clearing the status filter or search query.'
                                      : 'Placed orders will appear here.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: primaryColor,
                            onRefresh: () async {
                              await FirebaseFirestore.instance.collection('orders').get();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final doc = filtered[index];
                                return _buildOrderCard(context, doc.id, doc.data());
                              },
                            ),
                          ),
                  ),
                ],
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
        title: const Text('Manage Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  // ================================================================
  // STATUS CHIP
  // ================================================================
  Widget _statusChip(String status) {
    final bool isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(
        status,
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
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatusFilter = status);
        }
      },
    );
  }

  // ================================================================
  // ORDER CARD
  // ================================================================
  Widget _buildOrderCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> order,
  ) {
    final String orderId = order['orderId']?.toString() ?? docId;
    final String buyerName = order['buyerName']?.toString() ?? 'Buyer';
    final String status = order['status']?.toString() ?? order['orderStatus']?.toString() ?? 'Pending';
    final String shipmentStatus = order['shipmentStatus']?.toString() ?? 'Not Shipped';
    final String paymentMethod = order['paymentMethod']?.toString() ?? 'Cash on Delivery';
    final String paymentStatus = order['paymentStatus']?.toString() ?? 'Pending';
    final String paymentId = order['paymentId']?.toString() ?? '';
    final double total = _toDouble(order['totalAmount'] ?? order['totalPrice']);
    final Timestamp? timestamp = order['createdAt'] as Timestamp?;

    final bool isPaid = paymentStatus.toLowerCase() == 'paid';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xffE8F4F8),
                  child: Icon(Icons.receipt_long, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${_shortOrderId(orderId)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buyer: $buyerName',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Order Amount & Payment Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          paymentMethod.toLowerCase().contains('razorpay')
                              ? Icons.credit_card
                              : Icons.payments_outlined,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paymentMethod,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPaid ? 'Payment: PAID' : 'Payment: UNPAID',
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.orange.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (paymentId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Razorpay ID: $paymentId',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],

            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                'Placed: ${_formatDate(timestamp.toDate())} • Shipping: $shipmentStatus',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showFullOrderDetails(context, docId, order),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 4),

                // Order Status Menu
                PopupMenuButton<String>(
                  tooltip: 'Update Status',
                  onSelected: (val) {
                    if (val.startsWith('status:')) {
                      _updateField(context, docId, 'status', val.replaceFirst('status:', ''));
                    } else if (val.startsWith('ship:')) {
                      _updateField(context, docId, 'shipmentStatus', val.replaceFirst('ship:', ''));
                    } else if (val.startsWith('pay:')) {
                      _updateField(context, docId, 'paymentStatus', val.replaceFirst('pay:', ''));
                    } else if (val == 'delete') {
                      _confirmDeleteOrder(context, docId, orderId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('ORDER STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const PopupMenuItem(value: 'status:Pending', child: Text('Mark Pending')),
                    const PopupMenuItem(value: 'status:Confirmed', child: Text('Mark Confirmed')),
                    const PopupMenuItem(value: 'status:Shipped', child: Text('Mark Shipped')),
                    const PopupMenuItem(value: 'status:Delivered', child: Text('Mark Delivered')),
                    const PopupMenuItem(value: 'status:Cancelled', child: Text('Mark Cancelled', style: TextStyle(color: Colors.red))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('SHIPMENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const PopupMenuItem(value: 'ship:Not Shipped', child: Text('Not Shipped')),
                    const PopupMenuItem(value: 'ship:Processing', child: Text('Processing')),
                    const PopupMenuItem(value: 'ship:In Transit', child: Text('In Transit')),
                    const PopupMenuItem(value: 'ship:Delivered', child: Text('Shipment Delivered')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('PAYMENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const PopupMenuItem(value: 'pay:Paid', child: Text('Mark as Paid')),
                    const PopupMenuItem(value: 'pay:Pending', child: Text('Mark as Unpaid')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Order', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // STATUS BADGE
  // ================================================================
  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'shipped':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ================================================================
  // UPDATE FIRESTORE FIELD
  // ================================================================
  Future<void> _updateField(
    BuildContext context,
    String docId,
    String field,
    String value,
  ) async {
    try {
      final updates = <String, dynamic>{
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (field == 'status') {
        updates['orderStatus'] = value;
        if (value == 'Processing') {
          updates['shipmentStatus'] = 'Preparing';
        } else if (value == 'Shipped') {
          updates['shipmentStatus'] = 'Shipped';
        } else if (value == 'Delivered') {
          updates['shipmentStatus'] = 'Delivered';
        }
      } else if (field == 'shipmentStatus') {
        if (value == 'Preparing') {
          updates['status'] = 'Processing';
          updates['orderStatus'] = 'Processing';
        } else if (value == 'Shipped') {
          updates['status'] = 'Shipped';
          updates['orderStatus'] = 'Shipped';
        } else if (value == 'Delivered') {
          updates['status'] = 'Delivered';
          updates['orderStatus'] = 'Delivered';
        }
      }
      await FirebaseFirestore.instance.collection('orders').doc(docId).update(updates);

      // Notify Buyer if status or shipment status updated
      if (field == 'status' || field == 'shipmentStatus') {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('orders')
              .doc(docId)
              .get();
          final data = doc.data();
          if (data != null) {
            final buyerId = data['buyerId']?.toString() ?? '';
            final fishName = data['fishName']?.toString() ?? 'seafood order';
            final notifService = NotificationService();

            if (buyerId.isNotEmpty) {
              if (field == 'status') {
                await notifService.notifyUser(
                  userId: buyerId,
                  title: 'Order Status: $value',
                  message: 'Your order for $fishName status has been updated to $value by admin.',
                  type: value == 'Cancelled' ? 'order_cancelled' : 'system',
                  orderId: docId,
                );
              } else {
                await notifService.notifyUser(
                  userId: buyerId,
                  title: 'Shipment Status: $value',
                  message: 'Shipment status for $fishName is now: $value.',
                  type: value == 'Delivered' ? 'order_delivered' : 'order_shipped',
                  orderId: docId,
                );
              }
            }
          }
        } catch (notifErr) {
          debugPrint('Notification dispatch error on admin update: $notifErr');
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $field updated to "$value"'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================================================================
  // CONFIRM DELETE
  // ================================================================
  Future<void> _confirmDeleteOrder(
    BuildContext context,
    String docId,
    String orderId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to permanently delete Order #${_shortOrderId(orderId)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================================================================
  // FULL ORDER DETAILS MODAL
  // ================================================================
  void _showFullOrderDetails(
    BuildContext context,
    String docId,
    Map<String, dynamic> order,
  ) {
    final String orderId = order['orderId']?.toString() ?? docId;
    final String buyerName = order['buyerName']?.toString() ?? 'Buyer';
    final String buyerEmail = order['buyerEmail']?.toString() ?? 'No email';
    final String buyerPhone = order['buyerPhone']?.toString() ?? 'No phone';
    final String address = order['deliveryAddress']?.toString() ?? order['address']?.toString() ?? 'Not provided';
    final String city = order['city']?.toString() ?? '';
    final String pincode = order['pincode']?.toString() ?? '';
    final String status = order['status']?.toString() ?? order['orderStatus']?.toString() ?? 'Pending';
    final String shipmentStatus = order['shipmentStatus']?.toString() ?? 'Not Shipped';
    final String paymentMethod = order['paymentMethod']?.toString() ?? 'Cash on Delivery';
    final String paymentStatus = order['paymentStatus']?.toString() ?? 'Pending';
    final String paymentId = order['paymentId']?.toString() ?? '';
    final double total = _toDouble(order['totalAmount'] ?? order['totalPrice']);

    final dynamic rawItems = order['items'] ?? order['products'] ?? [];
    List<Map<String, dynamic>> items = [];
    if (rawItems is List) {
      items = rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${_shortOrderId(orderId)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 14),

              // Buyer Details Section
              const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xffF4F9FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: $buyerName', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Phone: $buyerPhone', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Email: $buyerEmail', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Address: $address, $city $pincode', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Ordered Items Section
              const Text('Ordered Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Text('${order['fishName'] ?? 'Fish Product'} (${order['quantity'] ?? 1} kg)', style: const TextStyle(color: Colors.grey))
              else
                ...items.map((it) {
                  final name = it['fishName'] ?? it['name'] ?? 'Product';
                  final qty = _toInt(it['quantity']);
                  final pr = _toDouble(it['price']);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• $name ($qty kg)', style: const TextStyle(fontSize: 14)),
                        Text('₹${(pr * qty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),

              const Divider(height: 24),

              // Payment Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method:', style: TextStyle(color: Colors.grey)),
                  Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Status:', style: TextStyle(color: Colors.grey)),
                  Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              if (paymentId.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Razorpay Payment ID:', style: TextStyle(color: Colors.grey)),
                    Text(paymentId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipment Status:', style: TextStyle(color: Colors.grey)),
                  Text(shipmentStatus, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  String _shortOrderId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}