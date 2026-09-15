import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/category_helper.dart';
import '../../widgets/report_complaint_dialog.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _filter = 'All'; // 'All', 'Pending', 'Processing', 'In Shipment', 'Completed'

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
      final Map<String, dynamic> updates = {
        'status': status,
        'orderStatus': status,
        'updatedAt': Timestamp.now(),
      };

      // Automatically advance shipment state as order progresses
      if (status == 'Processing') {
        updates['shipmentStatus'] = 'Preparing';
      } else if (status == 'Shipped') {
        updates['shipmentStatus'] = 'Shipped';
      } else if (status == 'In Transit') {
        updates['shipmentStatus'] = 'In Transit';
      } else if (status == 'Delivered' || status == 'Completed') {
        updates['shipmentStatus'] = 'Delivered';
      }

      await _firestore.collection('orders').doc(orderId).update(updates);

      // Dispatch notification to buyer
      try {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();
        final orderData = orderDoc.data();
        if (orderData != null) {
          final buyerId = orderData['buyerId']?.toString() ?? '';
          final fishName =
              orderData['fishName']?.toString() ?? 'seafood product';

          if (buyerId.isNotEmpty) {
            String notifTitle = 'Order Status Updated';
            String notifMsg =
                'Your order for $fishName status is now $status.';
            String notifType = 'system';

            switch (status) {
              case 'Accepted':
                notifTitle = 'Order Accepted! ⚓';
                notifMsg =
                    'The exporter has accepted your order for $fishName. Preparation will begin shortly.';
                notifType = 'order_accepted';
                break;
              case 'Processing':
                notifTitle = 'Order in Processing 📦';
                notifMsg =
                    'Your order for $fishName is now being processed and packed for export.';
                notifType = 'system';
                break;
              case 'Shipped':
                notifTitle = 'Consignment Shipped! 🚢';
                notifMsg =
                    'Your seafood consignment of $fishName has departed and is on its way.';
                notifType = 'order_shipped';
                break;
              case 'In Transit':
                notifTitle = 'Cargo In Transit 🌊';
                notifMsg =
                    'Your cargo of $fishName is in transit to your delivery destination.';
                notifType = 'order_shipped';
                break;
              case 'Delivered':
              case 'Completed':
                notifTitle = 'Order Delivered! 🎉';
                notifMsg =
                    'Your order for $fishName has been delivered successfully. Thank you!';
                notifType = 'order_delivered';
                break;
              case 'Rejected':
                notifTitle = 'Order Rejected ❌';
                notifMsg =
                    'Your order for $fishName could not be accepted by the exporter.';
                notifType = 'order_rejected';
                break;
            }

            await NotificationService().notifyUser(
              userId: buyerId,
              title: notifTitle,
              message: notifMsg,
              type: notifType,
              orderId: orderId,
            );
          }
        }
      } catch (notifErr) {
        debugPrint('Error sending status notification: $notifErr');
      }

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
      final Map<String, dynamic> updates = {
        'shipmentStatus': shipmentStatus,
        'updatedAt': Timestamp.now(),
      };

      // Automatically sync overall status
      if (shipmentStatus == 'Preparing') {
        updates['status'] = 'Processing';
        updates['orderStatus'] = 'Processing';
      } else if (shipmentStatus == 'Shipped') {
        updates['status'] = 'Shipped';
        updates['orderStatus'] = 'Shipped';
      } else if (shipmentStatus == 'In Transit') {
        updates['status'] = 'In Transit';
        updates['orderStatus'] = 'In Transit';
      } else if (shipmentStatus == 'Delivered') {
        updates['status'] = 'Delivered';
        updates['orderStatus'] = 'Delivered';
      }

      await _firestore.collection('orders').doc(orderId).update(updates);

      // Dispatch notification to buyer
      try {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();
        final orderData = orderDoc.data();
        if (orderData != null) {
          final buyerId = orderData['buyerId']?.toString() ?? '';
          final fishName =
              orderData['fishName']?.toString() ?? 'seafood consignment';

          if (buyerId.isNotEmpty) {
            String notifTitle = 'Shipment Update 🚢';
            String notifMsg =
                'Shipment status for $fishName is now: $shipmentStatus.';
            String notifType = 'order_shipped';

            switch (shipmentStatus) {
              case 'Preparing':
                notifTitle = 'Shipment Being Prepared 📦';
                notifMsg =
                    'Your consignment of $fishName is being prepared for dispatch.';
                break;
              case 'Shipped':
                notifTitle = 'Consignment Shipped! 🚢';
                notifMsg =
                    'Great news! Your cargo of $fishName has departed and is on its way.';
                notifType = 'order_shipped';
                break;
              case 'In Transit':
                notifTitle = 'Cargo In Transit 🌊';
                notifMsg =
                    'Your cargo of $fishName is in transit towards your delivery destination.';
                notifType = 'order_shipped';
                break;
              case 'Delivered':
                notifTitle = 'Shipment Delivered! 📬';
                notifMsg =
                    'Your shipment for $fishName has arrived and has been marked as delivered.';
                notifType = 'order_delivered';
                break;
            }

            await NotificationService().notifyUser(
              userId: buyerId,
              title: notifTitle,
              message: notifMsg,
              type: notifType,
              orderId: orderId,
            );
          }
        }
      } catch (notifErr) {
        debugPrint('Error sending shipment notification: $notifErr');
      }

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
      'Shipped',
      'In Transit',
      'Delivered',
      'Completed',
      'Rejected',
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
        return Icons.inventory_2;

      case 'Shipped':
        return Icons.local_shipping;

      case 'In Transit':
        return Icons.route;

      case 'Delivered':
        return Icons.verified;

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
        return Colors.blue;

      case 'Processing':
        return Colors.deepPurple;

      case 'Shipped':
        return Colors.indigo;

      case 'In Transit':
        return Colors.teal;

      case 'Delivered':
        return Colors.green;

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
                CategoryHelper.buildProductIcon(
                  category: data['category']?.toString() ?? 'Fish',
                  fishName: fishName,
                  size: 52,
                  borderRadius: 14,
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
            // SMART ACTION WORKFLOW BUTTONS
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'Accepted') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    updateOrderStatus(
                      orderId,
                      'Processing',
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text(
                    'Start Processing & Packing 📦',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff088395),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (status == 'Processing' || shipmentStatus == 'Preparing') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    updateShipmentStatus(
                      orderId,
                      'Shipped',
                    );
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text(
                    'Dispatch & Enter Shipment State 🚢',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4D68),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (status == 'Shipped' || shipmentStatus == 'Shipped') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        updateShipmentStatus(
                          orderId,
                          'In Transit',
                        );
                      },
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('In Transit 🌊'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        updateShipmentStatus(
                          orderId,
                          'Delivered',
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('Delivered 📬'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'In Transit' || shipmentStatus == 'In Transit') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    updateShipmentStatus(
                      orderId,
                      'Delivered',
                    );
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text(
                    'Mark as Delivered & Completed 📬',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (status == 'Delivered' || status == 'Completed' || shipmentStatus == 'Delivered') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Order Delivered & Completed Successfully 🎉',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: const Text(
                  'Report Issue / Cheating to Admin',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ReportComplaintDialog.show(
                    context,
                    orderId: orderId,
                    fishName: fishName,
                    accusedId: data['buyerId']?.toString(),
                    accusedName: buyerName,
                    accusedRole: 'Buyer',
                    userRole: 'Exporter',
                  );
                },
              ),
            ),
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

                final orders = snapshot.data?.docs ?? [];

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredOrders = orders.where((doc) {
                  final data = doc.data();
                  final st = (data['status'] ?? '').toString().toLowerCase();
                  final ship =
                      (data['shipmentStatus'] ?? '').toString().toLowerCase();

                  if (_filter == 'Pending') {
                    return st == 'pending';
                  } else if (_filter == 'Processing') {
                    return st == 'processing' ||
                        st == 'accepted' ||
                        ship == 'preparing';
                  } else if (_filter == 'In Shipment') {
                    return st == 'shipped' ||
                        st == 'in transit' ||
                        ship == 'shipped' ||
                        ship == 'in transit';
                  } else if (_filter == 'Completed') {
                    return st == 'completed' ||
                        st == 'delivered' ||
                        ship == 'delivered';
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    // Horizontal Filter Bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'All',
                            'Pending',
                            'Processing',
                            'In Shipment',
                            'Completed',
                          ].map((f) {
                            final isSel = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: isSel,
                                selectedColor: const Color(0xff0A4D68),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : Colors.black87,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _filter = f);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Text(
                                  'No orders found under "$_filter"',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final document = filteredOrders[index];
                                return _buildOrderCard(
                                  document.id,
                                  document.data(),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}