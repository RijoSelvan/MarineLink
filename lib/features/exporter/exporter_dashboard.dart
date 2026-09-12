import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/notifications_sheet.dart';
import 'exporter_add_fish_screen.dart';
import 'exporter_orders_screen.dart';
import 'exporter_profile_screen.dart';
import 'exporter_manage_products_screen.dart';
import '../../utils/category_helper.dart';

class ExporterDashboard extends StatefulWidget {
  const ExporterDashboard({super.key});

  @override
  State<ExporterDashboard> createState() => _ExporterDashboardState();
}

class _ExporterDashboardState extends State<ExporterDashboard> {
  int currentIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingOrdersSub;
  final Set<String> _handledOrderPopupIds = {};
  bool _isOrderDialogShowing = false;

  late final List<Widget> pages = [
    const ExporterHomeContent(),
    const Orders(),
    const ManageProductsScreen(),
    const UserProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForIncomingPendingOrders();
  }

  @override
  void dispose() {
    _pendingOrdersSub?.cancel();
    super.dispose();
  }

  // ============================================================
  // REAL-TIME INCOMING ORDER ACCEPT REQUEST POP-UP
  // ============================================================

  void _listenForIncomingPendingOrders() {
    final user = _auth.currentUser;
    if (user == null) return;

    _pendingOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('exporterId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;

          final String status = (data['status'] ?? data['orderStatus'] ?? '').toString().toLowerCase();
          final String orderId = change.doc.id;

          if (status == 'pending' && !_handledOrderPopupIds.contains(orderId)) {
            _handledOrderPopupIds.add(orderId);
            if (!_isOrderDialogShowing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_isOrderDialogShowing) {
                  _showIncomingOrderAcceptDialog(orderId, data);
                }
              });
            }
          }
        }
      }
    });
  }

  Widget _orderModalRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xff0A4D68),
            ),
          ),
        ),
      ],
    );
  }

  void _showIncomingOrderAcceptDialog(String orderId, Map<String, dynamic> data) {
    if (!mounted) return;
    _isOrderDialogShowing = true;

    final String buyerName = (data['buyerName'] ?? 'Buyer').toString();
    final String buyerPhone = (data['buyerPhone'] ?? '').toString();
    final String fishName = (data['fishName'] ?? 'Seafood Product').toString();
    final dynamic qty = data['quantity'] ?? 1;
    final num? amt = data['totalAmount'] as num?;
    final double total = amt?.toDouble() ?? 0.0;
    final String paymentMethod = (data['paymentMethod'] ?? 'COD').toString();
    final String paymentStatus = (data['paymentStatus'] ?? 'Pending').toString();
    final String address = (data['deliveryAddress'] ?? data['address'] ?? '').toString();
    final String city = (data['city'] ?? '').toString();
    final String shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with glowing badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.shade300, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.orange,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Incoming Order Request!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0A4D68),
                            ),
                          ),
                          Text(
                            'Order #$shortId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Order details card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF4F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: Column(
                    children: [
                      _orderModalRow('Buyer:', buyerName),
                      if (buyerPhone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _orderModalRow('Phone:', buyerPhone),
                      ],
                      const SizedBox(height: 6),
                      _orderModalRow('Product:', '$fishName ($qty kg)'),
                      const SizedBox(height: 6),
                      _orderModalRow('Total Amount:', '₹${total.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      _orderModalRow(
                        'Payment:',
                        '$paymentMethod (${paymentStatus.toUpperCase()})',
                        valueColor: paymentStatus.toLowerCase() == 'paid'
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _orderModalRow(
                          'Delivery Dest:',
                          city.isNotEmpty ? '$address, $city' : address,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons: Accept Order vs Reject
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.of(dialogCtx).pop();
                          _isOrderDialogShowing = false;
                          await _respondToIncomingOrder(orderId, data, 'Rejected');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          'Accept Order',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          Navigator.of(dialogCtx).pop();
                          _isOrderDialogShowing = false;
                          await _respondToIncomingOrder(orderId, data, 'Accepted');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _isOrderDialogShowing = false;
                    },
                    child: Text(
                      'Review Later',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isOrderDialogShowing = false;
    });
  }

  Future<void> _respondToIncomingOrder(
    String orderId,
    Map<String, dynamic> data,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'orderStatus': newStatus,
        'updatedAt': Timestamp.now(),
      });

      final buyerId = data['buyerId']?.toString() ?? '';
      final fishName = data['fishName']?.toString() ?? 'product';

      if (buyerId.isNotEmpty) {
        if (newStatus == 'Accepted') {
          await NotificationService().notifyUser(
            userId: buyerId,
            title: 'Order Accepted! ⚓',
            message: 'The exporter has accepted your order for $fishName. Preparation will begin shortly.',
            type: 'order_accepted',
            orderId: orderId,
          );
        } else if (newStatus == 'Rejected') {
          await NotificationService().notifyUser(
            userId: buyerId,
            title: 'Order Rejected ❌',
            message: 'Your order for $fishName could not be accepted by the exporter.',
            type: 'order_rejected',
            orderId: orderId,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Accepted'
                ? 'Order Accepted! Customer has been notified.'
                : 'Order rejected.',
          ),
          backgroundColor: newStatus == 'Accepted' ? Colors.green : Colors.red,
        ),
      );

      if (newStatus == 'Accepted') {
        _changePage(1); // Jump to Orders screen
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      if (!mounted) return;

      // Remove all previous screens and go to Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xff0A4D68),
              ),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your exporter account?',
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
                // Close dialog first
                Navigator.pop(dialogContext);

                // Perform logout
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4D68),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CHANGE PAGE
  // ============================================================

  void _changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    final String email =
        currentUser?.email ?? 'No email available';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exporter Dashboard',
        ),
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(
              _auth.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 26,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      final uid = _auth.currentUser?.uid;
                      if (uid != null && uid.isNotEmpty) {
                        NotificationsSheet.show(context, uid);
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ========================================================
      // DRAWER
      // ========================================================

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xff0A4D68),
              ),
              accountName: const Text(
                'Fish Exporter',
              ),
              accountEmail: Text(
                email,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.directions_boat_rounded,
                  size: 38,
                  color: Color(0xff0A4D68),
                ),
              ),
            ),

            // ----------------------------------------------------
            // DASHBOARD
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Dashboard',
              ),
              selected: currentIndex == 0,
              selectedColor: const Color(0xff0A4D68),
              onTap: () {
                _changePage(0);
                Navigator.pop(context);
              },
            ),

            // ----------------------------------------------------
            // ADD FISH
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Add Catch',
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddFishScreen(),
                  ),
                );
              },
            ),

            // ----------------------------------------------------
            // PRODUCTS
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.set_meal_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Products & Stock',
              ),
              selected: currentIndex == 2,
              selectedColor: const Color(0xff0A4D68),
              onTap: () {
                _changePage(2);
                Navigator.pop(context);
              },
            ),

            // ----------------------------------------------------
            // ORDERS
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Orders & Shipments',
              ),
              selected: currentIndex == 1,
              selectedColor: const Color(0xff0A4D68),
              onTap: () {
                _changePage(1);
                Navigator.pop(context);
              },
            ),

            // ----------------------------------------------------
            // PROFILE
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.account_circle_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Profile',
              ),
              selected: currentIndex == 3,
              selectedColor: const Color(0xff0A4D68),
              onTap: () {
                _changePage(3);
                Navigator.pop(context);
              },
            ),

            // ----------------------------------------------------
            // NOTIFICATIONS
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xff0A4D68),
              ),
              title: const Text(
                'Notifications',
              ),
              trailing: StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(
                  _auth.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.pop(context);
                final uid = _auth.currentUser?.uid;
                if (uid != null && uid.isNotEmpty) {
                  NotificationsSheet.show(context, uid);
                }
              },
            ),

            const Divider(),

            // ----------------------------------------------------
            // LOGOUT
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // ========================================================
      // ADD FISH BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_circle_rounded,
          size: 22,
        ),
        label: const Text(
          'Add Catch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddFishScreen(),
            ),
          );
        },
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xff0A4D68),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          _changePage(value);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.grid_view_outlined,
            ),
            activeIcon: Icon(
              Icons.grid_view_rounded,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_shipping_outlined,
            ),
            activeIcon: Icon(
              Icons.local_shipping_rounded,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.set_meal_outlined,
            ),
            activeIcon: Icon(
              Icons.set_meal_rounded,
            ),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle_outlined,
            ),
            activeIcon: Icon(
              Icons.account_circle_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPORTER HOME CONTENT
// ============================================================

class ExporterHomeContent extends StatefulWidget {
  const ExporterHomeContent({super.key});

  @override
  State<ExporterHomeContent> createState() => _ExporterHomeContentState();
}

class _ExporterHomeContentState extends State<ExporterHomeContent> {
  String _statsPeriod = 'today'; // 'today', 'monthwise', 'overall'
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  void _pickMonthYear(BuildContext context) {
    int tempYear = _selectedYear;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Month & Year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0A4D68),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setDialogState(() {
                            tempYear--;
                          });
                        },
                      ),
                      Text(
                        '$tempYear',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setDialogState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNumber = index + 1;
                    final isSelected = monthNumber == _selectedMonth && tempYear == _selectedYear;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedMonth = monthNumber;
                          _selectedYear = tempYear;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xff0A4D68) : const Color(0xffF4F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xff0A4D68) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _monthNames[index].substring(0, 3),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // WELCOME
          // ====================================================

          // ====================================================
          // WELCOME BANNER
          // ====================================================

          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Icon(Icons.sailing_rounded, color: Color(0xFF05BFDB), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Exporter Portal Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🚢', style: TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    String name = 'Exporter';
                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!.data();
                      if (data != null && data['name'] != null) {
                        name = data['name'].toString().trim();
                      }
                    }
                    return Text(
                      'Welcome, $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your catches, orders, and shipments in real-time.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ====================================================
          // STATISTICS (LIVE)
          // ============================================          // ====================================================
          // STATISTICS (TODAY VS MONTHWISE VS OVERALL)
          // ====================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statsPeriod == 'today'
                    ? "Today's Statistics"
                    : _statsPeriod == 'monthwise'
                        ? "${_monthNames[_selectedMonth - 1]} $_selectedYear Stats"
                        : "Overall Statistics",
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0A4D68),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statsPeriod == 'today'
                      ? Colors.green.withValues(alpha: 0.12)
                      : _statsPeriod == 'monthwise'
                          ? Colors.orange.withValues(alpha: 0.12)
                          : const Color(0xff0A4D68).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statsPeriod == 'today'
                      ? 'LIVE TODAY'
                      : _statsPeriod == 'monthwise'
                          ? 'MONTHWISE'
                          : 'OVERALL',
                  style: TextStyle(
                    color: _statsPeriod == 'today'
                        ? Colors.green.shade800
                        : _statsPeriod == 'monthwise'
                            ? Colors.orange.shade900
                            : const Color(0xff0A4D68),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3-way Segmented selector chips: Today vs Monthwise vs Overall
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  avatar: Icon(
                    Icons.today_rounded,
                    size: 16,
                    color: _statsPeriod == 'today' ? Colors.white : const Color(0xff0A4D68),
                  ),
                  label: const Text("Today's Overview"),
                  selected: _statsPeriod == 'today',
                  selectedColor: const Color(0xff0A4D68),
                  labelStyle: TextStyle(
                    color: _statsPeriod == 'today' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _statsPeriod = 'today');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: _statsPeriod == 'monthwise' ? Colors.white : const Color(0xff0A4D68),
                  ),
                  label: const Text("Monthwise Stats"),
                  selected: _statsPeriod == 'monthwise',
                  selectedColor: const Color(0xff0A4D68),
                  labelStyle: TextStyle(
                    color: _statsPeriod == 'monthwise' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _statsPeriod = 'monthwise');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(
                    Icons.all_inclusive_rounded,
                    size: 16,
                    color: _statsPeriod == 'overall' ? Colors.white : const Color(0xff0A4D68),
                  ),
                  label: const Text("Overall Stats"),
                  selected: _statsPeriod == 'overall',
                  selectedColor: const Color(0xff0A4D68),
                  labelStyle: TextStyle(
                    color: _statsPeriod == 'overall' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _statsPeriod = 'overall');
                  },
                ),
              ],
            ),
          ),

          // Interactive Month Selector Bar when in Monthwise mode
          if (_statsPeriod == 'monthwise') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff0A4D68).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xff0A4D68)),
                    tooltip: 'Previous Month',
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        } else {
                          _selectedMonth--;
                        }
                      });
                    },
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _pickMonthYear(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xff0A4D68)),
                          const SizedBox(width: 8),
                          Text(
                            '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0A4D68),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Color(0xff0A4D68)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xff0A4D68)),
                    tooltip: 'Next Month',
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 12) {
                          _selectedMonth = 1;
                          _selectedYear++;
                        } else {
                          _selectedMonth++;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('exporterId', isEqualTo: uid)
                .snapshots(),
            builder: (context, productSnapshot) {
              final productDocs = productSnapshot.data?.docs ?? [];
              final int productCount = productDocs.length;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('exporterId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, orderSnapshot) {
                  final orderDocs = orderSnapshot.data?.docs ?? [];

                  final now = DateTime.now();
                  final startOfToday = DateTime(now.year, now.month, now.day);

                  // Today's Counters
                  int todayOrders = 0;
                  double todayRevenue = 0.0;
                  int todayShipments = 0;
                  int todayPending = 0;

                  // Monthwise Counters
                  int monthOrders = 0;
                  double monthRevenue = 0.0;
                  int monthShipments = 0;
                  int monthDelivered = 0;

                  // Overall / All-Time Counters
                  int lifetimeOrders = orderDocs.length;
                  double lifetimeRevenue = 0.0;
                  int lifetimeShipments = 0;

                  for (final doc in orderDocs) {
                    final data = doc.data();
                    final String status = data['status']?.toString().toLowerCase() ?? '';
                    final String shipmentStatus = data['shipmentStatus']?.toString().toLowerCase() ?? '';
                    final num? amt = data['totalAmount'] as num?;
                    final double val = amt?.toDouble() ?? 0.0;

                    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
                    final DateTime? dt = createdAt?.toDate();
                    final bool isToday = dt != null && dt.isAfter(startOfToday);
                    final bool isChosenMonth = dt != null && dt.year == _selectedYear && dt.month == _selectedMonth;

                    // Overall aggregation
                    if (status != 'cancelled' && status != 'rejected') {
                      lifetimeRevenue += val;
                    }
                    if (shipmentStatus.isNotEmpty && shipmentStatus != 'not shipped') {
                      lifetimeShipments++;
                    }

                    // Today aggregation
                    if (isToday) {
                      todayOrders++;
                      if (status != 'cancelled' && status != 'rejected') {
                        todayRevenue += val;
                      }
                      if (shipmentStatus.isNotEmpty && shipmentStatus != 'not shipped') {
                        todayShipments++;
                      }
                      if (status == 'pending' || status == 'confirmed') {
                        todayPending++;
                      }
                    }

                    // Monthwise aggregation
                    if (isChosenMonth) {
                      monthOrders++;
                      if (status != 'cancelled' && status != 'rejected') {
                        monthRevenue += val;
                      }
                      if (shipmentStatus.isNotEmpty && shipmentStatus != 'not shipped') {
                        monthShipments++;
                      }
                      if (status == 'delivered' || status == 'completed' || shipmentStatus == 'delivered') {
                        monthDelivered++;
                      }
                    }
                  }

                  return Column(
                    children: [
                      if (_statsPeriod == 'today') ...[
                        // TODAY'S CARDS
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: "Today's Orders",
                                value: '$todayOrders',
                                icon: Icons.receipt_long_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: "Today's Revenue",
                                value: '₹${todayRevenue.toStringAsFixed(0)}',
                                icon: Icons.currency_rupee_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: "Today's Shipments",
                                value: '$todayShipments',
                                icon: Icons.directions_boat_rounded,
                                iconColor: const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: "Pending Actions",
                                value: '$todayPending',
                                icon: Icons.hourglass_top_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_statsPeriod == 'monthwise') ...[
                        // MONTHWISE CARDS
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: "${_monthNames[_selectedMonth - 1].substring(0, 3)} Orders",
                                value: '$monthOrders',
                                icon: Icons.receipt_long_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: "${_monthNames[_selectedMonth - 1].substring(0, 3)} Revenue",
                                value: '₹${monthRevenue.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: "${_monthNames[_selectedMonth - 1].substring(0, 3)} Shipments",
                                value: '$monthShipments',
                                icon: Icons.directions_boat_rounded,
                                iconColor: const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: "Delivered",
                                value: '$monthDelivered',
                                icon: Icons.task_alt_rounded,
                                iconColor: const Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // OVERALL CARDS (renamed from "Till Now")
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Products',
                                value: '$productCount',
                                icon: Icons.set_meal_rounded,
                                iconColor: const Color(0xFF0A4D68),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Overall Orders',
                                value: '$lifetimeOrders',
                                icon: Icons.sailing_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Overall Revenue',
                                value: '₹${lifetimeRevenue.toStringAsFixed(0)}',
                                icon: Icons.payments_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Overall Shipments',
                                value: '$lifetimeShipments',
                                icon: Icons.anchor_rounded,
                                iconColor: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Dynamic Summary Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xffF4F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 18, color: Color(0xff0A4D68)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statsPeriod == 'today'
                                    ? "Today's Live: ₹${todayRevenue.toStringAsFixed(0)} revenue ($todayOrders orders) • Overall: ₹${lifetimeRevenue.toStringAsFixed(0)} ($lifetimeOrders orders)"
                                    : _statsPeriod == 'monthwise'
                                        ? "${_monthNames[_selectedMonth - 1]} $_selectedYear: ₹${monthRevenue.toStringAsFixed(0)} revenue ($monthOrders orders) • Overall: ₹${lifetimeRevenue.toStringAsFixed(0)}"
                                        : "Overall Cumulative Record: ₹${lifetimeRevenue.toStringAsFixed(0)} total revenue across $lifetimeOrders orders",
                                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 30),

          // ====================================================
          // QUICK ACTIONS
          // ====================================================

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _buildActionCard(
                context,
                icon: Icons.set_meal_rounded,
                title: 'Add Catch',
                subtitle: 'List fresh fish & stock',
                badgeText: 'New',
                gradientColors: const [Color(0xFF088395), Color(0xFF05BFDB)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddFishScreen(),
                    ),
                  );
                },
              ),

              _buildActionCard(
                context,
                icon: Icons.inventory_2_rounded,
                title: 'Inventory',
                subtitle: 'Manage stock & boxes',
                badgeText: 'Stock',
                gradientColors: const [Color(0xFF0A4D68), Color(0xFF1E88E5)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageProductsScreen(),
                    ),
                  );
                },
              ),

              _buildActionCard(
                context,
                icon: Icons.local_shipping_rounded,
                title: 'Shipments',
                subtitle: 'Live buyer orders',
                badgeText: 'Orders',
                gradientColors: const [Color(0xFFEA580C), Color(0xFFF59E0B)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Orders(),
                    ),
                  );
                },
              ),

              _buildActionCard(
                context,
                icon: Icons.auto_graph_rounded,
                title: 'Analytics',
                subtitle: 'Sales & profit reports',
                badgeText: 'Reports',
                gradientColors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                onTap: () => _showReportsModal(context, uid),
              ),

              _buildActionCard(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Order Alerts',
                subtitle: 'Buyer requests & notices',
                badgeText: 'Alerts',
                gradientColors: const [Color(0xFFE11D48), Color(0xFFF43F5E)],
                onTap: () {
                  if (uid.isNotEmpty) {
                    NotificationsSheet.show(context, uid);
                  }
                },
              ),

              _buildActionCard(
                context,
                icon: Icons.verified_user_rounded,
                title: 'Exporter ID',
                subtitle: 'Profile & export license',
                badgeText: 'Profile',
                gradientColors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfile(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ====================================================
          // RECENT ACTIVITY
          // ====================================================

          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('exporterId', isEqualTo: uid)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff0A4D68).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sailing_rounded,
                            size: 44,
                            color: Color(0xff0A4D68),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No recent orders yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Customer orders for your fish products will appear here.',
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

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final String fishName =
                        data['fishName']?.toString() ?? 'Fish Product';
                    final String status =
                        data['status']?.toString() ?? 'Pending';
                    final num amount = (data['totalAmount'] as num?) ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xffE8F4F8),
                        backgroundImage: AssetImage(
                          CategoryHelper.getCategoryAssetImage(
                            CategoryHelper.determineCategory(
                              category: data['category']?.toString(),
                              fishName: fishName,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        fishName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Status: $status'),
                      trailing: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0A4D68),
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  void _showReportsModal(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('exporterId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              int pending = 0;
              int accepted = 0;
              int delivered = 0;
              int cancelled = 0;
              double totalRevenue = 0.0;

              for (final doc in docs) {
                final data = doc.data();
                final String status =
                    data['status']?.toString().toLowerCase() ?? '';
                final num? amt = data['totalAmount'] as num?;

                if (status == 'pending') {
                  pending++;
                } else if (status == 'delivered') {
                  delivered++;
                } else if (status == 'cancelled' || status == 'rejected') {
                  cancelled++;
                } else {
                  accepted++;
                }

                if (status != 'cancelled' && status != 'rejected') {
                  if (amt != null) totalRevenue += amt.toDouble();
                }
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Export Business Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0A4D68),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comprehensive performance overview',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Total revenue highlight
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0A4D68), Color(0xff088395)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Sales Revenue',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${totalRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Orders Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildReportRow(
                            'Total Orders Received',
                            '${docs.length}',
                            Icons.receipt,
                            Colors.blue,
                          ),
                          _buildReportRow(
                            'Pending Review',
                            '$pending',
                            Icons.hourglass_empty,
                            Colors.orange,
                          ),
                          _buildReportRow(
                            'In Processing / Shipped',
                            '$accepted',
                            Icons.sync,
                            Colors.purple,
                          ),
                          _buildReportRow(
                            'Delivered Orders',
                            '$delivered',
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildReportRow(
                            'Cancelled Orders',
                            '$cancelled',
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF4F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    String badge = 'Live',
    IconData trendIcon = Icons.trending_up_rounded,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor,
                      iconColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 12, color: const Color(0xFF10B981)),
                    const SizedBox(width: 2),
                    Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: gradientColors.first.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: gradientColors.first,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
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
}