import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  // ================================================================
  // GET BUYER ORDERS
  // ================================================================

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

  // ================================================================
  // STATUS COLOR
  // ================================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'processing':
        return Colors.deepPurple;

      case 'shipped':
        return Colors.indigo;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // STATUS ICON
  // ================================================================

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;

      case 'accepted':
        return Icons.check_circle_outline;

      case 'processing':
        return Icons.sync;

      case 'shipped':
        return Icons.local_shipping;

      case 'delivered':
        return Icons.done_all;

      case 'cancelled':
        return Icons.cancel;

      default:
        return Icons.info_outline;
    }
  }

  // ================================================================
  // FORMAT DATE
  // ================================================================

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final DateTime date = timestamp.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return 'Date unavailable';
  }

  // ================================================================
  // CONVERSION HELPER
  // ================================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ================================================================
  // INTEGER CONVERSION
  // ================================================================

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ================================================================
  // ORDER CARD
  // ================================================================

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    final String orderId =
        data['orderId']?.toString() ?? document.id;

    final String status =
        data['status']?.toString() ?? 'Pending';

    final double totalAmount =
        _toDouble(data['totalAmount']);

    final String paymentMethod =
        data['paymentMethod']?.toString() ?? 'Not specified';

    final String createdAt =
        _formatDate(data['createdAt']);

    final List<dynamic> items =
        data['items'] is List ? data['items'] as List : [];

    final Color statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showOrderDetails(
            context,
            data,
            document.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================================
              // ORDER HEADER
              // ========================================================

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xff0A4D68),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order ID',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          orderId.length > 16
                              ? '${orderId.substring(0, 16)}...'
                              : orderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Divider(),

              const SizedBox(height: 10),

              // ========================================================
              // ORDER INFORMATION
              // ========================================================

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.calendar_today,
                      'Date',
                      createdAt,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.shopping_bag,
                      'Items',
                      '${items.length}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.payment,
                      'Payment',
                      paymentMethod,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.currency_rupee,
                      'Total',
                      '₹${totalAmount.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ========================================================
              // VIEW DETAILS
              // ========================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xff0A4D68),
                    side: const BorderSide(
                      color: Color(0xff0A4D68),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showOrderDetails(
                      context,
                      data,
                      document.id,
                    );
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),
                  label: const Text(
                    'VIEW ORDER DETAILS',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // INFO ITEM
  // ================================================================

  Widget _infoItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xff0A4D68),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ORDER DETAILS DIALOG
  // ================================================================

  void _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String documentId,
  ) {
    final String orderId =
        data['orderId']?.toString() ?? documentId;

    final String status =
        data['status']?.toString() ?? 'Pending';

    final double totalAmount =
        _toDouble(data['totalAmount']);

    final String paymentMethod =
        data['paymentMethod']?.toString() ??
            'Not specified';

    final String address =
        data['deliveryAddress']?.toString() ??
            data['address']?.toString() ??
            'Address not available';

    final List<dynamic> items =
        data['items'] is List ? data['items'] as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // HANDLE

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

                // TITLE

                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // STATUS

                        _statusTimeline(status),

                        const SizedBox(height: 25),

                        // DELIVERY ADDRESS

                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xffF4F9FF),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xff0A4D68),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ITEMS

                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (items.isEmpty)
                          const Text(
                            'No item details available.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                        ...items.map(
                          (item) {
                            if (item is! Map) {
                              return const SizedBox();
                            }

                            final String name =
                                item['fishName']?.toString() ??
                                    item['name']?.toString() ??
                                    'Product';

                            final int quantity =
                                _toInt(item['quantity']);

                            final double price =
                                _toDouble(item['price']);

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 10,
                              ),
                              padding:
                                  const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor:
                                        Color(0xffE8F4F8),
                                    child: Icon(
                                      Icons.set_meal,
                                      color:
                                          Color(0xff0A4D68),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$quantity kg × ₹${price.toStringAsFixed(2)}',
                                          style:
                                              const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    '₹${(price * quantity).toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // PAYMENT

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffF4F9FF),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Payment Method',
                                  ),
                                  Text(
                                    paymentMethod,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              const Divider(),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Color(0xff0A4D68),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // STATUS TIMELINE
  // ================================================================

  Widget _statusTimeline(String currentStatus) {
    const List<String> statuses = [
      'Pending',
      'Accepted',
      'Processing',
      'Shipped',
      'Delivered',
    ];

    int currentIndex = statuses.indexWhere(
      (status) =>
          status.toLowerCase() ==
          currentStatus.toLowerCase(),
    );

    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return Column(
      children: [
        Row(
          children: List.generate(
            statuses.length,
            (index) {
              final bool completed =
                  index <= currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? const Color(0xff0A4D68)
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        index == 0
                            ? Icons.access_time
                            : index == 1
                                ? Icons.check
                                : index == 2
                                    ? Icons.inventory_2
                                    : index == 3
                                        ? Icons.local_shipping
                                        : Icons.done_all,
                        size: 16,
                        color: completed
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),

                    if (index != statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index < currentIndex
                              ? const Color(0xff0A4D68)
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: statuses
              .map(
                (status) => SizedBox(
                  width: 65,
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          status.toLowerCase() ==
                                  currentStatus.toLowerCase()
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          status.toLowerCase() ==
                                  currentStatus.toLowerCase()
                              ? const Color(0xff0A4D68)
                              : Colors.grey,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
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
          'My Orders',
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _getOrders(),
        builder: (context, snapshot) {
          // LOADING

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff0A4D68),
              ),
            );
          }

          // ERROR

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load orders.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders =
              snapshot.data?.docs ?? [];

          // NO ORDERS

          if (orders.isEmpty) {
            return _emptyOrders(context);
          }

          // ORDERS

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _orderCard(
                context,
                orders[index],
              );
            },
          );
        },
      ),
    );
  }

  // ================================================================
  // EMPTY ORDERS
  // ================================================================

  Widget _emptyOrders(BuildContext context) {
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
                Icons.receipt_long_outlined,
                size: 75,
                color: Color(0xff0A4D68),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Your placed orders will appear here.',
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
                padding:
                    const EdgeInsets.symmetric(
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
                'SHOP NOW',
              ),
            ),
          ],
        ),
      ),
    );
  }
}