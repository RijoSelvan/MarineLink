import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // GET EXPORTER ORDERS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrders() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('orders')
        .where('exporterId', isEqualTo: user.uid)
        .snapshots();
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to $status',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE SHIPMENT STATUS
  // ============================================================

  Future<void> updateShipmentStatus(
    String orderId,
    String shipmentStatus,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'shipmentStatus': shipmentStatus,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shipment status updated to $shipmentStatus',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update shipment: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ORDER STATUS DIALOG
  // ============================================================

  void showOrderStatusDialog(
    String orderId,
    String currentStatus,
  ) {
    final List<String> statuses = [
      'Pending',
      'Accepted',
      'Processing',
      'Rejected',
      'Completed',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Order Status',
            style: TextStyle(
              color: Color(0xff0A4D68),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                title: Text(status),
                trailing: currentStatus == status
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(dialogContext);

                  if (currentStatus != status) {
                    await updateOrderStatus(
                      orderId,
                      status,
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ============================================================
  // SHIPMENT STATUS DIALOG
  // ============================================================

  void showShipmentStatusDialog(
    String orderId,
    String currentStatus,
  ) {
    final List<String> statuses = [
      'Not Shipped',
      'Preparing',
      'Shipped',
      'In Transit',
      'Delivered',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Shipment Status',
            style: TextStyle(
              color: Color(0xff0A4D68),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                leading: Icon(
                  _getShipmentIcon(status),
                  color: _getShipmentColor(status),
                ),
                title: Text(status),
                trailing: currentStatus == status
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(dialogContext);

                  if (currentStatus != status) {
                    await updateShipmentStatus(
                      orderId,
                      status,
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;

      case 'Accepted':
        return Icons.check_circle;

      case 'Processing':
        return Icons.settings;

      case 'Rejected':
        return Icons.cancel;

      case 'Completed':
        return Icons.done_all;

      default:
        return Icons.info_outline;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;

      case 'Accepted':
        return Colors.green;

      case 'Processing':
        return Colors.blue;

      case 'Rejected':
        return Colors.red;

      case 'Completed':
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // SHIPMENT ICON
  // ============================================================

  IconData _getShipmentIcon(String status) {
    switch (status) {
      case 'Not Shipped':
        return Icons.inventory_2_outlined;

      case 'Preparing':
        return Icons.inventory;

      case 'Shipped':
        return Icons.local_shipping;

      case 'In Transit':
        return Icons.route;

      case 'Delivered':
        return Icons.check_circle;

      default:
        return Icons.local_shipping_outlined;
    }
  }

  // ============================================================
  // SHIPMENT COLOR
  // ============================================================

  Color _getShipmentColor(String status) {
    switch (status) {
      case 'Not Shipped':
        return Colors.grey;

      case 'Preparing':
        return Colors.orange;

      case 'Shipped':
        return Colors.blue;

      case 'In Transit':
        return Colors.deepPurple;

      case 'Delivered':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Date not available';
    }

    try {
      if (value is Timestamp) {
        final DateTime date = value.toDate();

        return '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';
      }

      return value.toString();
    } catch (_) {
      return 'Date not available';
    }
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    String orderId,
    Map<String, dynamic> data,
  ) {
    final String buyerName =
        data['buyerName']?.toString() ?? 'Unknown Buyer';

    final String fishName =
        data['fishName']?.toString() ?? 'Unknown Fish';

    final dynamic quantity =
        data['quantity'] ?? 0;

    final dynamic price =
        data['price'] ?? 0;

    final dynamic totalAmount =
        data['totalAmount'] ?? 0;

    final String status =
        data['status']?.toString() ?? 'Pending';

    final String paymentStatus =
        data['paymentStatus']?.toString() ?? 'Pending';

    final String shipmentStatus =
        data['shipmentStatus']?.toString() ?? 'Not Shipped';

    final String deliveryAddress =
        data['deliveryAddress']?.toString() ??
            'Address not available';

    final String orderDate =
        _formatDate(data['createdAt']);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ORDER HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xffE3F2F7),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Color(0xff0A4D68),
                    size: 32,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        fishName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xff0A4D68),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Buyer: $buyerName',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Order ID: $orderId',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
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

            // ==================================================
            // ORDER DETAILS
            // ==================================================

            _detailRow(
              Icons.scale,
              'Quantity',
              '$quantity Kg',
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.currency_rupee,
              'Price',
              '₹$price / Kg',
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.payments,
              'Total Amount',
              '₹$totalAmount',
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.calendar_today,
              'Order Date',
              orderDate,
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.location_on,
              'Delivery Address',
              deliveryAddress,
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATUS CHIPS
            // ==================================================

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  Icons.info_outline,
                  status,
                  _getStatusColor(status),
                ),

                _statusChip(
                  Icons.payment,
                  paymentStatus,
                  paymentStatus
                          .toLowerCase()
                          .contains('paid')
                      ? Colors.green
                      : Colors.orange,
                ),

                _statusChip(
                  _getShipmentIcon(
                    shipmentStatus,
                  ),
                  shipmentStatus,
                  _getShipmentColor(
                    shipmentStatus,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 8),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showOrderStatusDialog(
                        orderId,
                        status,
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                    ),
                    label: const Text(
                      'Order Status',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showShipmentStatusDialog(
                        orderId,
                        shipmentStatus,
                      );
                    },
                    icon: const Icon(
                      Icons.local_shipping,
                      size: 18,
                    ),
                    label: const Text(
                      'Shipment',
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // QUICK ACCEPT / REJECT
            // ==================================================

            if (status == 'Pending') ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        updateOrderStatus(
                          orderId,
                          'Accepted',
                        );
                      },
                      icon: const Icon(
                        Icons.check,
                      ),
                      label: const Text(
                        'Accept Order',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,
                        foregroundColor:
                            Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        updateOrderStatus(
                          orderId,
                          'Rejected',
                        );
                      },
                      icon: const Icon(
                        Icons.close,
                      ),
                      label: const Text(
                        'Reject',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                        foregroundColor:
                            Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xff0A4D68),
        ),

        const SizedBox(width: 8),

        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius:
            BorderRadius.circular(20),
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
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 90,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Customer orders will appear here when buyers place orders for your products.',
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
  // LOGIN REQUIRED
  // ============================================================

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'Exporter Not Logged In',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Please login to view your orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xffF4F9FF),

      appBar: AppBar(
        title: const Text(
          'My Orders',
        ),
        backgroundColor:
            const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: user == null
          ? _buildLoginRequired()
          : StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
              stream: getOrders(),
              builder:
                  (context, snapshot) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 70,
                            color: Colors.red,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Text(
                            'Unable to load orders',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            '${snapshot.error}',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ------------------------------------------------
                // ORDERS
                // ------------------------------------------------

                final orders =
                    snapshot.data?.docs ?? [];

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder:
                      (context, index) {
                    final document =
                        orders[index];

                    return _buildOrderCard(
                      document.id,
                      document.data(),
                    );
                  },
                );
              },
            ),
    );
  }
}