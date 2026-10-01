import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;

  const AdminHome({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return _errorView('Unable to load user statistics.');
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0A4D68)),
          );
        }

        final users = userSnapshot.data?.docs ?? [];
        int buyers = 0;
        int exporters = 0;
        int admins = 0;

        for (final document in users) {
          final data = document.data();
          final role = data['role']?.toString().toLowerCase() ?? '';
          if (role == 'buyer') {
            buyers++;
          } else if (role == 'exporter') {
            exporters++;
          } else if (role == 'admin') {
            admins++;
          }
        }

        return _buildDashboard(
          context,
          totalUsers: users.length,
          buyers: buyers,
          exporters: exporters,
          admins: admins,
        );
      },
    );
  }

  // ================================================================
  // DASHBOARD
  // ================================================================
  Widget _buildDashboard(
    BuildContext context, {
    required int totalUsers,
    required int buyers,
    required int exporters,
    required int admins,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // WELCOME CARD
          // ==========================================================
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
                          Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF05BFDB), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Administrator Control Center',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('📊', style: TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    String name = 'Admin';
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
                  'Full platform oversight: users, exports, transactions, and inventory.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // PLATFORM OVERVIEW (METRICS)
          // ==========================================================
          const Text(
            'Platform Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff0A4D68),
            ),
          ),
          const SizedBox(height: 14),

          // First Row: Users & Buyers
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  icon: Icons.people,
                  iconColor: Colors.blue,
                  onTap: () => onSelectTab?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Buyers',
                  value: '$buyers',
                  icon: Icons.shopping_bag,
                  iconColor: Colors.orange,
                  onTap: () => onSelectTab?.call(1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second Row: Exporters & Products
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Exporters',
                  value: '$exporters',
                  icon: Icons.local_shipping,
                  iconColor: Colors.green,
                  onTap: () => onSelectTab?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _firestoreCountCard(
                  collection: 'products',
                  title: 'Products',
                  icon: Icons.inventory_2,
                  iconColor: Colors.purple,
                  onTap: () => onSelectTab?.call(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Third Row: Orders & Revenue
          Row(
            children: [
              Expanded(
                child: _firestoreCountCard(
                  collection: 'orders',
                  title: 'Total Orders',
                  icon: Icons.receipt_long,
                  iconColor: Colors.red,
                  onTap: () => onSelectTab?.call(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _revenueCard(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fourth Row: Complaints & Dispute Oversight
          Row(
            children: [
              Expanded(
                child: _firestoreCountCard(
                  collection: 'complaints',
                  title: 'Complaints / Cheating',
                  icon: Icons.gavel_rounded,
                  iconColor: Colors.deepOrange,
                  onTap: () => onSelectTab?.call(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ==========================================================
          // QUICK ACTIONS
          // ==========================================================
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff0A4D68),
            ),
          ),
          const SizedBox(height: 12),

          _quickAction(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            subtitle: 'Manage buyers, exporters, and user roles',
            index: 1,
          ),

          _quickAction(
            context,
            icon: Icons.inventory_2,
            title: 'Manage Products',
            subtitle: 'Review seafood inventory and stock levels',
            index: 2,
          ),

          _quickAction(
            context,
            icon: Icons.receipt_long,
            title: 'Manage Orders',
            subtitle: 'Process orders, track shipments & payments',
            index: 3,
          ),

          _quickAction(
            context,
            icon: Icons.gavel,
            title: 'Disputes & Cheating Oversight',
            subtitle: 'Validate cheating, quality grievances & fraud',
            index: 4,
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // RECENT ORDERS SECTION
          // ==========================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0A4D68),
                ),
              ),
              TextButton(
                onPressed: () => onSelectTab?.call(3),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildRecentOrdersPreview(context),

          const SizedBox(height: 24),

          // ==========================================================
          // RECENT USERS SECTION
          // ==========================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Registrations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0A4D68),
                ),
              ),
              TextButton(
                onPressed: () => onSelectTab?.call(1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildRecentUsersPreview(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================================================================
  // RECENT ORDERS PREVIEW
  // ================================================================
  Widget _buildRecentOrdersPreview(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No orders recorded yet.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        // Sort descending by createdAt or index
        final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
        sortedDocs.sort((a, b) {
          final timeA = a.data()['createdAt'] as Timestamp?;
          final timeB = b.data()['createdAt'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        final topOrders = sortedDocs.take(3).toList();

        return Column(
          children: topOrders.map((doc) {
            final data = doc.data();
            final orderId = data['orderId']?.toString() ?? doc.id;
            final buyerName = data['buyerName']?.toString() ?? 'Buyer';
            final total = (data['totalAmount'] ?? data['totalPrice'] ?? 0.0);
            final status = data['status']?.toString() ?? data['orderStatus']?.toString() ?? 'Pending';
            final paymentStatus = data['paymentStatus']?.toString() ?? 'Pending';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                onTap: () => onSelectTab?.call(3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xffE8F4F8),
                  child: const Icon(Icons.receipt, color: Color(0xff0A4D68), size: 20),
                ),
                title: Text(
                  'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Buyer: $buyerName • ₹${total is num ? total.toStringAsFixed(2) : total}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentStatus == 'Paid' ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: paymentStatus == 'Paid' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================================================================
  // RECENT USERS PREVIEW
  // ================================================================
  Widget _buildRecentUsersPreview(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No users found.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        final topUsers = docs.take(3).toList();

        return Column(
          children: topUsers.map((doc) {
            final data = doc.data();
            final name = data['name']?.toString() ?? 'User';
            final email = data['email']?.toString() ?? 'No email';
            final role = data['role']?.toString() ?? 'User';

            Color roleCol = Colors.blue;
            if (role.toLowerCase() == 'admin') roleCol = Colors.red;
            if (role.toLowerCase() == 'exporter') roleCol = Colors.green;
            if (role.toLowerCase() == 'buyer') roleCol = Colors.orange;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                onTap: () => onSelectTab?.call(1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: roleCol.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(color: roleCol, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleCol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: roleCol,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================================================================
  // BASIC STAT CARD
  // ================================================================
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A4D68).withValues(alpha: 0.04),
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
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
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
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FIRESTORE COUNT CARD
  // ================================================================
  Widget _firestoreCountCard({
    required String collection,
    required String title,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _statCard(
            title: title,
            value: '0',
            icon: icon,
            iconColor: iconColor,
            onTap: onTap,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingStatCard(title, icon, iconColor);
        }

        final count = snapshot.data?.docs.length ?? 0;
        return _statCard(
          title: title,
          value: '$count',
          icon: icon,
          iconColor: iconColor,
          onTap: onTap,
        );
      },
    );
  }

  // ================================================================
  // REVENUE CARD
  // ================================================================
  Widget _revenueCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        double revenue = 0;
        if (snapshot.hasData) {
          for (final document in snapshot.data!.docs) {
            final data = document.data();
            final dynamic value = data['totalAmount'] ?? data['totalPrice'];
            if (value is num) {
              revenue += value.toDouble();
            } else if (value is String) {
              revenue += double.tryParse(value) ?? 0;
            }
          }
        }

        return _statCard(
          title: 'Total Revenue',
          value: '₹${revenue.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
          iconColor: Colors.teal,
          onTap: () => onSelectTab?.call(3),
        );
      },
    );
  }

  // ================================================================
  // LOADING STAT CARD
  // ================================================================
  Widget _loadingStatCard(String title, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff0A4D68)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTION
  // ================================================================
  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xffE8F4F8),
          child: Icon(icon, color: const Color(0xff0A4D68)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          onSelectTab?.call(index);
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 15),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}