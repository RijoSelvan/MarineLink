import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'exporter_add_fish_screen.dart';
import 'exporter_orders_screen.dart';
import 'exporter_profile_screen.dart';
import 'exporter_manage_products_screen.dart';

class ExporterDashboard extends StatefulWidget {
  const ExporterDashboard({super.key});

  @override
  State<ExporterDashboard> createState() => _ExporterDashboardState();
}

class _ExporterDashboardState extends State<ExporterDashboard> {
  int currentIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final List<Widget> pages = [
    const ExporterHomeContent(),
    const Orders(),
    const ManageProductsScreen(),
    const UserProfile(),
  ];

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
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No new notifications',
                  ),
                ),
              );
            },
          ),
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
                  Icons.person,
                  size: 40,
                  color: Color(0xff0A4D68),
                ),
              ),
            ),

            // ----------------------------------------------------
            // DASHBOARD
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.dashboard_outlined,
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
                Icons.add_box_outlined,
              ),
              title: const Text(
                'Add Fish',
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
                Icons.inventory_2_outlined,
              ),
              title: const Text(
                'Products',
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
                Icons.shopping_cart_outlined,
              ),
              title: const Text(
                'Orders',
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
                Icons.person_outline,
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

            const Divider(),

            // ----------------------------------------------------
            // LOGOUT
            // ----------------------------------------------------

            ListTile(
              leading: const Icon(
                Icons.logout,
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add,
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
              Icons.dashboard_outlined,
            ),
            activeIcon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_cart_outlined,
            ),
            activeIcon: Icon(
              Icons.shopping_cart,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.inventory_2_outlined,
            ),
            activeIcon: Icon(
              Icons.inventory_2,
            ),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
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

class ExporterHomeContent extends StatelessWidget {
  const ExporterHomeContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // WELCOME
          // ====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff0A4D68),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Exporter 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Manage your seafood business from one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ====================================================
          // STATISTICS
          // ====================================================

          const Text(
            "Today's Statistics",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Products',
                  value: '0',
                  icon: Icons.inventory_2,
                  iconColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Orders',
                  value: '0',
                  icon: Icons.shopping_cart,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Revenue',
                  value: '₹0',
                  icon: Icons.currency_rupee,
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Shipments',
                  value: '0',
                  icon: Icons.local_shipping,
                  iconColor: Colors.red,
                ),
              ),
            ],
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
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                context,
                Icons.add_box,
                'Add Fish',
                () {
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
                Icons.inventory_2,
                'Products',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ManageProductsScreen(),
                    ),
                  );
                },
              ),

              _buildActionCard(
                context,
                Icons.shopping_cart,
                'Orders',
                () {
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
                Icons.analytics,
                'Reports',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Reports module will be added later.',
                      ),
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

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 50,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Your recent orders and product updates will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 45,
              color: const Color(0xff0A4D68),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}