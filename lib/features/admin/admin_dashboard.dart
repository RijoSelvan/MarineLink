import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'admin_home.dart';
import 'admin_manage_orders_screen.dart';
import 'admin_manage_products_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_manage_complaints_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentIndex = 0;

  final List<String> titles = const [
    'Admin Dashboard',
    'Manage Users',
    'Manage Products',
    'Manage Orders',
    'Disputes & Cheating',
    'Admin Profile',
  ];

  late final List<Widget> pages = [
    AdminHome(onSelectTab: (index) => setState(() => currentIndex = index)),
    const AdminManageUsersScreen(isEmbedded: true),
    const AdminManageProductsScreen(isEmbedded: true),
    const AdminManageOrdersScreen(isEmbedded: true),
    const AdminManageComplaintsScreen(isEmbedded: true),
    const AdminProfileScreen(isEmbedded: true),
  ];

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.notifications, color: Color(0xff0A4D68)),
                  SizedBox(width: 8),
                  Text(
                    'Admin Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('status', isEqualTo: 'Pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data?.docs.length ?? 0;
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xffE8F4F8),
                        child: Icon(Icons.receipt_long, color: Color(0xff0A4D68)),
                      ),
                      title: Text('$pendingCount Pending Orders awaiting fulfillment'),
                      subtitle: const Text('Tap to view and process orders'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => currentIndex = 3);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xffE8F4F8),
                    child: Icon(Icons.security, color: Colors.green),
                  ),
                  title: Text('Payment Gateway Active'),
                  subtitle: Text('Razorpay is active and accepting transactions'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out from the Admin Portal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          titles[currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _showNotificationsSheet,
          ),
        ],
      ),

      // ============================================================
      // DRAWER
      // ============================================================

      drawer: _buildDrawer(),

      // ============================================================
      // BODY
      // ============================================================

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff0A4D68),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            activeIcon: Icon(Icons.gavel),
            label: 'Disputes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? {};
              final name = data['name']?.toString() ?? 'Administrator';
              final email = data['email']?.toString() ?? user?.email ?? 'admin@marinelink.com';

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff0A4D68), Color(0xff088395)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(email),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Color(0xff0A4D68),
                  ),
                ),
              );
            },
          ),

          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentIndex == 0,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 0);
              Navigator.pop(context);
            },
          ),

          // Users
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            selected: currentIndex == 1,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 1);
              Navigator.pop(context);
            },
          ),

          // Products
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Manage Products'),
            selected: currentIndex == 2,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 2);
              Navigator.pop(context);
            },
          ),

          // Orders
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Manage Orders'),
            selected: currentIndex == 3,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 3);
              Navigator.pop(context);
            },
          ),

          // Disputes & Cheating Complaints
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Disputes & Cheating'),
            selected: currentIndex == 4,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 4);
              Navigator.pop(context);
            },
          ),

          // Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            selected: currentIndex == 5,
            selectedColor: const Color(0xff0A4D68),
            onTap: () {
              setState(() => currentIndex = 5);
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }
}