import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/notifications_sheet.dart';
import 'buyer_home.dart';
import 'buyer_cart_screen.dart';
import 'buyer_orders_screen.dart';
import 'buyer_wishlist_screen.dart';
import 'buyer_profile_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int currentIndex = 0;

  List<Widget> get pages => [
        const BuyerHome(),
        const BuyerWishlistScreen(),
        BuyerCartScreen(onBrowse: () => setState(() => currentIndex = 0)),
        BuyerOrdersScreen(onBrowse: () => setState(() => currentIndex = 0)),
        const BuyerProfileScreen(),
      ];

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Remove all previous screens and go to Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Logout failed",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Logout failed: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM LOGOUT
  // ============================================================

  Future<void> _confirmLogout() async {
    // Close drawer first
    Navigator.pop(context);

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Logout",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4D68),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                "Logout",
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff0A4D68),
                Color(0xff088395),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/categories/all.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "MarineLink",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
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

      // ==========================================================
      // DRAWER
      // ==========================================================

      drawer: _buildDrawer(),

      // ==========================================================
      // BODY
      // ==========================================================

      body: pages[currentIndex],

      // ==========================================================
      // FLOATING CART BUTTON
      // ==========================================================

      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xff0A4D68),
              foregroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  currentIndex = 2;
                });
              },
              child: const Icon(
                Icons.shopping_bag_rounded,
              ),
            )
          : null,

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A4D68).withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0A4D68),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: "Wishlist",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag_rounded),
              label: "Cart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt_rounded),
              label: "Orders",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF061A28),
                  Color(0xFF0A4D68),
                  Color(0xFF088395),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: const Text(
              "MarineLink Buyer",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: const Text(
              "Direct seafood consumer portal",
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF05BFDB), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/categories/all.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ======================================================
          // HOME
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.storefront_rounded,
            ),
            title: const Text(
              "Home",
            ),
            onTap: () {
              setState(() {
                currentIndex = 0;
              });

              Navigator.pop(context);
            },
          ),

          // ======================================================
          // WISHLIST
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.favorite_rounded,
            ),
            title: const Text(
              "Wishlist",
            ),
            onTap: () {
              setState(() {
                currentIndex = 1;
              });

              Navigator.pop(context);
            },
          ),

          // ======================================================
          // CART
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.shopping_bag_rounded,
            ),
            title: const Text(
              "My Cart",
            ),
            onTap: () {
              setState(() {
                currentIndex = 2;
              });

              Navigator.pop(context);
            },
          ),

          // ======================================================
          // ORDERS
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.list_alt_rounded,
            ),
            title: const Text(
              "My Orders",
            ),
            onTap: () {
              setState(() {
                currentIndex = 3;
              });

              Navigator.pop(context);
            },
          ),

          // ======================================================
          // PROFILE
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.person_rounded,
            ),
            title: const Text(
              "Profile",
            ),
            onTap: () {
              setState(() {
                currentIndex = 4;
              });

              Navigator.pop(context);
            },
          ),

          // ======================================================
          // NOTIFICATIONS
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF0A4D68),
            ),
            title: const Text(
              "Notifications",
            ),
            trailing: StreamBuilder<int>(
              stream: NotificationService().getUnreadCountStream(
                FirebaseAuth.instance.currentUser?.uid ?? '',
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
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null && uid.isNotEmpty) {
                NotificationsSheet.show(context, uid);
              }
            },
          ),

          const Divider(),

          // ======================================================
          // LOGOUT
          // ======================================================

          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}