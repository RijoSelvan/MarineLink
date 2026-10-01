import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin_mail_dialog.dart';


class AdminManageUsersScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminManageUsersScreen({super.key, this.isEmbedded = true});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final Color primaryColor = const Color(0xff0A4D68);
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRoleFilter = 'All'; // 'All', 'Buyer', 'Exporter', 'Admin'

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
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
              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
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

              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _roleFilterChip('All'),
                    const SizedBox(width: 8),
                    _roleFilterChip('Buyer'),
                    const SizedBox(width: 8),
                    _roleFilterChip('Exporter'),
                    const SizedBox(width: 8),
                    _roleFilterChip('Admin'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // ==========================================================
        // USERS STREAM LIST
        // ==========================================================
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _errorView('Unable to load users.\n${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];

              // Filter users
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data();
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final phone = (data['phone'] ?? '').toString().toLowerCase();
                final role = (data['role'] ?? '').toString().toLowerCase();

                // Role filter
                if (_selectedRoleFilter != 'All' &&
                    role != _selectedRoleFilter.toLowerCase()) {
                  return false;
                }

                // Search query filter
                if (_searchQuery.isNotEmpty) {
                  final matchName = name.contains(_searchQuery);
                  final matchEmail = email.contains(_searchQuery);
                  final matchPhone = phone.contains(_searchQuery);
                  if (!matchName && !matchEmail && !matchPhone) {
                    return false;
                  }
                }

                return true;
              }).toList();

              // Sort in memory by name or createdAt safely
              filteredDocs.sort((a, b) {
                final aData = a.data();
                final bData = b.data();
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime != null && bTime != null) {
                  return bTime.compareTo(aTime);
                }
                final aName = (aData['name'] ?? '').toString().toLowerCase();
                final bName = (bData['name'] ?? '').toString().toLowerCase();
                return aName.compareTo(bName);
              });

              if (filteredDocs.isEmpty) {
                return _emptyView();
              }

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  await FirebaseFirestore.instance.collection('users').get();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocs[index];
                    return _userCard(context, document.id, document.data());
                  },
                ),
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
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  // ================================================================
  // FILTER CHIP
  // ================================================================
  Widget _roleFilterChip(String role) {
    final bool isSelected = _selectedRoleFilter == role;
    return ChoiceChip(
      label: Text(
        role,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey.shade300,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRoleFilter = role;
          });
        }
      },
    );
  }

  // ================================================================
  // USER CARD
  // ================================================================
  Widget _userCard(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    final String name = data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString().trim()
        : 'Unknown User';

    final String email = data['email']?.toString() ?? 'No email';
    final String phone = data['phone']?.toString() ?? 'No phone';
    final String role = data['role']?.toString() ?? 'User';
    final bool isVerified = data['isVerified'] == true;

    Color roleColor;
    IconData roleIcon;

    final roleLower = role.toLowerCase();
    if (roleLower == 'admin') {
      roleColor = Colors.red;
      roleIcon = Icons.admin_panel_settings;
    } else if (roleLower == 'exporter') {
      roleColor = Colors.green;
      roleIcon = Icons.local_shipping;
    } else if (roleLower == 'buyer') {
      roleColor = Colors.orange;
      roleIcon = Icons.shopping_bag;
    } else {
      roleColor = Colors.grey;
      roleIcon = Icons.person;
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Icon(roleIcon, color: roleColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            // Exporter Metrics Banner
            if (roleLower == 'exporter') ...[
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('exporterId', isEqualTo: userId)
                    .snapshots(),
                builder: (ctx, prodSnap) {
                  final int productCount = prodSnap.data?.docs.length ?? 0;
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('exporterId', isEqualTo: userId)
                        .snapshots(),
                    builder: (ctx, ordSnap) {
                      double revenue = 0.0;
                      final orders = ordSnap.data?.docs ?? [];
                      for (final ord in orders) {
                        final oData = ord.data();
                        final st = (oData['status'] ?? '').toString().toLowerCase();
                        if (st != 'cancelled' && st != 'rejected') {
                          final num? amt = oData['totalAmount'] as num?;
                          if (amt != null) revenue += amt.toDouble();
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xffE8F4F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff088395).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xff0A4D68)),
                                const SizedBox(width: 4),
                                Text(
                                  'Products: $productCount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xff0A4D68),
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 14, color: Colors.grey.shade300),
                            Row(
                              children: [
                                const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                                const SizedBox(width: 2),
                                Text(
                                  'Revenue: ₹${revenue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],

            // Buyer Metrics Banner
            if (roleLower == 'buyer') ...[
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('buyerId', isEqualTo: userId)
                    .snapshots(),
                builder: (ctx, ordSnap) {
                  final orders = ordSnap.data?.docs ?? [];
                  double spent = 0.0;
                  for (final ord in orders) {
                    final oData = ord.data();
                    final st = (oData['status'] ?? '').toString().toLowerCase();
                    if (st != 'cancelled' && st != 'rejected') {
                      final num? amt = oData['totalAmount'] as num?;
                      if (amt != null) spent += amt.toDouble();
                    }
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Orders: ${orders.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 14, color: Colors.grey.shade300),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 14, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(
                              'Spent: ₹${spent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                // Actions Menu
                TextButton.icon(
                  onPressed: () => _showUserDetails(context, userId, data),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                ),
                TextButton.icon(
                  onPressed: () {
                    AdminMailDialog.show(
                      context: context,
                      recipientName: name,
                      recipientEmail: email,
                      recipientRole: role,
                      recipientUserId: userId,
                    );
                  },
                  icon: const Icon(Icons.mail_outline_rounded, size: 16),
                  label: const Text('Email'),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'email') {
                      AdminMailDialog.show(
                        context: context,
                        recipientName: name,
                        recipientEmail: email,
                        recipientRole: role,
                        recipientUserId: userId,
                      );
                    } else if (action == 'change_role') {
                      _showChangeRoleDialog(context, userId, name, role);
                    } else if (action == 'toggle_verify') {
                      _toggleVerification(context, userId, isVerified);
                    } else if (action == 'delete') {
                      _confirmDeleteUser(context, userId, name);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'email',
                      child: Row(
                        children: [
                          Icon(Icons.mail_outline, size: 18, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text('Send Mail / Notice'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_role',
                      child: Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Change Role'),
                        ],
                      ),
                    ),
                    if (roleLower == 'exporter')
                      PopupMenuItem(
                        value: 'toggle_verify',
                        child: Row(
                          children: [
                            Icon(
                              isVerified ? Icons.cancel_outlined : Icons.verified_outlined,
                              size: 18,
                              color: isVerified ? Colors.orange : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(isVerified ? 'Remove Verification' : 'Verify Exporter'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_vert, size: 20, color: Colors.grey),
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
  // CHANGE ROLE DIALOG
  // ================================================================
  void _showChangeRoleDialog(
    BuildContext context,
    String userId,
    String userName,
    String currentRole,
  ) {
    String selectedNewRole = currentRole.toLowerCase();
    if (!['buyer', 'exporter', 'admin'].contains(selectedNewRole)) {
      selectedNewRole = 'buyer';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Change Role for $userName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a new access role:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _roleSelectOption(
                    title: 'Buyer (Customer)',
                    subtitle: 'Can browse fish & place orders',
                    isSelected: selectedNewRole == 'buyer',
                    onTap: () => setDialogState(() => selectedNewRole = 'buyer'),
                  ),
                  _roleSelectOption(
                    title: 'Exporter (Vendor)',
                    subtitle: 'Can add seafood & manage stock',
                    isSelected: selectedNewRole == 'exporter',
                    onTap: () => setDialogState(() => selectedNewRole = 'exporter'),
                  ),
                  _roleSelectOption(
                    title: 'Admin (Portal Manager)',
                    subtitle: 'Full access to platform operations',
                    isSelected: selectedNewRole == 'admin',
                    onTap: () => setDialogState(() => selectedNewRole = 'admin'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'role': selectedNewRole,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated $userName to ${selectedNewRole.toUpperCase()}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Save Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _roleSelectOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TOGGLE VERIFICATION
  // ================================================================
  Future<void> _toggleVerification(
    BuildContext context,
    String userId,
    bool currentStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isVerified': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? 'Exporter verified' : 'Exporter verification revoked'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================================================================
  // DELETE USER
  // ================================================================
  Future<void> _confirmDeleteUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete User Record'),
        content: Text(
          'Are you sure you want to delete "$userName" from Firestore?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
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
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================================================================
  // USER DETAILS DIALOG
  // ================================================================
  void _showUserDetails(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    final String name = data['name']?.toString() ?? 'Unknown';
    final String email = data['email']?.toString() ?? 'No email';
    final String phone = data['phone']?.toString() ?? 'No phone';
    final String role = data['role']?.toString() ?? 'Unknown';
    final String address = data['address']?.toString() ?? data['location']?.toString() ?? 'Not specified';
    final String godownAddress = data['godownAddress']?.toString() ?? 'Not specified';
    final bool isVerified = data['isVerified'] == true;
    final bool isExporter = role.toLowerCase() == 'exporter';
    final bool isBuyer = role.toLowerCase() == 'buyer';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isExporter ? Icons.local_shipping : (isBuyer ? Icons.shopping_bag : Icons.person),
                color: const Color(0xff0A4D68),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$name (${role.toUpperCase()})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Full Name', name),
                  _detailRow('Email Address', email),
                  _detailRow('Phone Number', phone),
                  _detailRow('Role', role.toUpperCase()),
                  _detailRow('Verified Status', isVerified ? 'Verified Exporter ✅' : 'Standard / Unverified'),
                  _detailRow('Registered Address', address),
                  if (isExporter) _detailRow('Exporter Godown Address ⚓', godownAddress),

                  const Divider(height: 24),

                  // ==========================================
                  // EXPORTER SPECIFIC: PRODUCTS & REVENUE
                  // ==========================================
                  if (isExporter) ...[
                    const Text(
                      'Exporter Performance & Inventory',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0A4D68)),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('exporterId', isEqualTo: userId)
                          .snapshots(),
                      builder: (ctx, prodSnap) {
                        final productDocs = prodSnap.data?.docs ?? [];
                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('exporterId', isEqualTo: userId)
                              .snapshots(),
                          builder: (ctx, ordSnap) {
                            double revenue = 0.0;
                            final orderDocs = ordSnap.data?.docs ?? [];
                            for (final ord in orderDocs) {
                              final oData = ord.data();
                              final st = (oData['status'] ?? '').toString().toLowerCase();
                              if (st != 'cancelled' && st != 'rejected') {
                                final num? amt = oData['totalAmount'] as num?;
                                if (amt != null) revenue += amt.toDouble();
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffE8F4F8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xff0A4D68).withValues(alpha: 0.15)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('Total Products', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                            const SizedBox(height: 4),
                                            Text('${productDocs.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0A4D68))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('Total Revenue', style: TextStyle(fontSize: 11, color: Colors.green)),
                                            const SizedBox(height: 4),
                                            Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('Listed Products:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                if (productDocs.isEmpty)
                                  const Text('No products listed by this exporter yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                                else
                                  ...productDocs.take(5).map((p) {
                                    final pData = p.data();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text('• ${pData['fishName'] ?? 'Product'} (${pData['category'] ?? ''})', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                          ),
                                          Text('₹${pData['price'] ?? 0}/kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],

                  // ==========================================
                  // BUYER SPECIFIC: ORDER HISTORY & TOTAL SPENT
                  // ==========================================
                  if (isBuyer) ...[
                    const Text(
                      'Buyer Order History & Spending',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0A4D68)),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('buyerId', isEqualTo: userId)
                          .snapshots(),
                      builder: (ctx, ordSnap) {
                        final orderDocs = ordSnap.data?.docs ?? [];
                        double totalSpent = 0.0;
                        for (final ord in orderDocs) {
                          final oData = ord.data();
                          final st = (oData['status'] ?? '').toString().toLowerCase();
                          if (st != 'cancelled' && st != 'rejected') {
                            final num? amt = oData['totalAmount'] as num?;
                            if (amt != null) totalSpent += amt.toDouble();
                          }
                        }

                        // Sort orders by createdAt descending
                        final sortedOrders = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(orderDocs);
                        sortedOrders.sort((a, b) {
                          final aTime = a.data()['createdAt'] as Timestamp?;
                          final bTime = b.data()['createdAt'] as Timestamp?;
                          if (aTime != null && bTime != null) return bTime.compareTo(aTime);
                          return 0;
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('Total Orders', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                        const SizedBox(height: 4),
                                        Text('${orderDocs.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('Total Amount Spent', style: TextStyle(fontSize: 11, color: Colors.teal)),
                                        const SizedBox(height: 4),
                                        Text('₹${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text('Order History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (sortedOrders.isEmpty)
                              const Text('No orders placed yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                            else
                              ...sortedOrders.take(6).map((ordDoc) {
                                final oData = ordDoc.data();
                                final String orderId = oData['orderId']?.toString() ?? ordDoc.id;
                                final double amt = ((oData['totalAmount'] as num?) ?? 0).toDouble();
                                final String st = oData['status']?.toString() ?? 'Pending';
                                final String fish = oData['fishName']?.toString() ?? 'Order';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF4F9FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} - $fish',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Status: $st',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: st.toLowerCase() == 'completed' || st.toLowerCase() == 'delivered'
                                                    ? Colors.green
                                                    : Colors.orange.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${amt.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff0A4D68)),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 14),
            const Text(
              'No users found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedRoleFilter != 'All'
                  ? 'Try adjusting your search query or filter.'
                  : 'Registered users will appear here.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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