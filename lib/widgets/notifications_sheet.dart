import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsSheet extends StatefulWidget {
  final String userId;

  const NotificationsSheet({super.key, required this.userId});

  static void show(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(userId: userId),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final NotificationService _notificationService = NotificationService();
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFF0A4D68), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'mark_read') {
                      _notificationService.markAllAsRead(widget.userId);
                    } else if (value == 'clear_all') {
                      _notificationService.clearAll(widget.userId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF088395)),
                          SizedBox(width: 8),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Clear all'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: !_onlyUnread,
                  onSelected: (val) => setState(() => _onlyUnread = false),
                  selectedColor: const Color(0xFF0A4D68),
                  labelStyle: TextStyle(
                    color: !_onlyUnread ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Unread Only'),
                  selected: _onlyUnread,
                  onSelected: (val) => setState(() => _onlyUnread = true),
                  selectedColor: const Color(0xFF0A4D68),
                  labelStyle: TextStyle(
                    color: _onlyUnread ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications Stream List
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getNotificationsStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0A4D68)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading notifications: ${snapshot.error}'),
                  );
                }

                var list = snapshot.data ?? [];
                if (_onlyUnread) {
                  list = list.where((n) => !n.isRead).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A4D68).withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.notifications_off_outlined,
                            size: 40,
                            color: Color(0xFF0A4D68),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onlyUnread ? 'No unread notifications' : 'No notifications yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You will be notified here about order updates and actions.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildNotificationItem(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    final config = _getNotificationConfig(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        _notificationService.deleteNotification(item.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) {
            _notificationService.markAsRead(item.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Timestamp & Order ID Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.orderId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A4D68).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${item.orderId.length > 7 ? item.orderId.substring(0, 7) : item.orderId}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A4D68),
                              ),
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
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime dt = timestamp.toDate();
    final Duration diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  _TypeConfig _getNotificationConfig(String type) {
    switch (type) {
      case 'new_order':
        return _TypeConfig(Icons.shopping_bag_rounded, const Color(0xFF0A4D68));
      case 'order_placed':
        return _TypeConfig(Icons.receipt_long_rounded, const Color(0xFF088395));
      case 'order_accepted':
        return _TypeConfig(Icons.check_circle_rounded, const Color(0xFF10B981));
      case 'order_shipped':
        return _TypeConfig(Icons.sailing_rounded, const Color(0xFF05BFDB));
      case 'order_delivered':
        return _TypeConfig(Icons.verified_rounded, const Color(0xFF10B981));
      case 'order_cancelled':
        return _TypeConfig(Icons.cancel_rounded, const Color(0xFFFF6B6B));
      case 'order_rejected':
        return _TypeConfig(Icons.highlight_off_rounded, Colors.red);
      default:
        return _TypeConfig(Icons.notifications_rounded, const Color(0xFF0A4D68));
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;

  _TypeConfig(this.icon, this.color);
}
