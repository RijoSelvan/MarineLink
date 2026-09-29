import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/admin_mail_dialog.dart';

class AdminManageComplaintsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminManageComplaintsScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminManageComplaintsScreen> createState() =>
      _AdminManageComplaintsScreenState();
}

class _AdminManageComplaintsScreenState
    extends State<AdminManageComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final Color primaryColor = const Color(0xff0A4D68);

  String _selectedStatusFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Completed',
    'Validated (Cheating Confirmed)',
    'Dismissed',
  ];


  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final bool isSelected = _selectedStatusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: filter.contains('Validated')
                        ? Colors.red.shade700
                        : primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedStatusFilter = filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const Divider(height: 1),

        // Stream list
        Expanded(
          child: StreamBuilder<List<Complaint>>(
            stream: _complaintService.getAllComplaintsStream(
              statusFilter: _selectedStatusFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading complaints:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final complaints = snapshot.data ?? [];
              if (complaints.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No complaints found',
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedStatusFilter != 'All'
                            ? 'No reports with status "$_selectedStatusFilter"'
                            : 'All platform interactions are compliant and grievance-free.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: complaints.length,
                itemBuilder: (ctx, index) {
                  return _buildComplaintCard(complaints[index]);
                },
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
        title: const Text('Dispute & Cheating Oversight', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    Color statusColor;
    IconData statusIcon;
    final st = complaint.status.toLowerCase();

    if (st.contains('validated') || st.contains('cheating')) {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.warning_rounded;
    } else if (st.contains('resolved') || st.contains('completed')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (st.contains('dismissed')) {
      statusColor = Colors.grey.shade600;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.report_problem_rounded, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        complaint.type,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        complaint.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Complainant & Accused Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF4F9FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        'Reported by: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        '${complaint.complaintByName} (${complaint.complaintByRole})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Accused: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        '${complaint.accusedName} (${complaint.accusedRole})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (complaint.orderId != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.receipt_outlined, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text(
                          'Order Reference: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        Text(
                          '#${complaint.orderId!.length > 14 ? complaint.orderId!.substring(0, 14) : complaint.orderId}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Description
            const Text(
              'Grievance Statement:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),

            // Admin remarks if already validated
            if (complaint.adminRemarks != null && complaint.adminRemarks!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.brown),
                        SizedBox(width: 4),
                        Text(
                          'Admin Validation Remarks:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.adminRemarks!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Date & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(complaint.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    // Email Parties button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded, size: 16),
                      label: const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _showMailOptions(complaint),
                    ),

                    // Action verdict button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.rule_rounded, size: 16),
                      label: const Text('Take Action', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showValidationDialog(complaint),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMailOptions(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xff0A4D68)),
                    const SizedBox(width: 8),
                    const Text(
                      'Official Admin Communication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0A4D68),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Case #${complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id} - ${complaint.type}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Option 1: Complainant
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffE8F4F8),
                    child: Icon(Icons.person, color: Color(0xff0A4D68)),
                  ),
                  title: Text('Email Complainant (${complaint.complaintByName})'),
                  subtitle: Text(
                    complaint.complaintByEmail.isNotEmpty
                        ? complaint.complaintByEmail
                        : 'Tap to enter email',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(bCtx);
                    AdminMailDialog.show(
                      context: context,
                      recipientName: complaint.complaintByName,
                      recipientEmail: complaint.complaintByEmail,
                      recipientRole: complaint.complaintByRole,
                      recipientUserId: complaint.complaintBy,
                      caseReference: complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id,
                      initialSubject: '[MarineLink Admin] Update on Your Grievance #${complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id}',
                      initialBody: 'Dear ${complaint.complaintByName},\n\nWe have reviewed your report regarding order #${complaint.orderId ?? 'N/A'} (${complaint.type}) against ${complaint.accusedName}.\n\nCurrent Status: ${complaint.status}\n${complaint.adminRemarks != null && complaint.adminRemarks!.isNotEmpty ? "Admin Remarks: ${complaint.adminRemarks}\n" : ""}\nPlease reply to this email or check your MarineLink portal if you have questions.\n\nRegards,\nMarineLink Administration Team',
                    );
                  },
                ),

                const Divider(),

                // Option 2: Accused Party
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffFDE8E8),
                    child: Icon(Icons.shield_outlined, color: Colors.red),
                  ),
                  title: Text('Email Accused (${complaint.accusedName})'),
                  subtitle: Text(
                    '${complaint.accusedRole} • Official Notice & Inquiries',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    Navigator.pop(bCtx);
                    String accusedEmail = '';
                    if (complaint.accusedId != null && complaint.accusedId!.isNotEmpty) {
                      try {
                        final uDoc = await FirebaseFirestore.instance.collection('users').doc(complaint.accusedId).get();
                        if (uDoc.exists) {
                          accusedEmail = uDoc.data()?['email']?.toString() ?? '';
                        }
                      } catch (_) {}
                    }
                    if (!mounted) return;
                    AdminMailDialog.show(
                      context: context,
                      recipientName: complaint.accusedName,
                      recipientEmail: accusedEmail,
                      recipientRole: complaint.accusedRole,
                      recipientUserId: complaint.accusedId,
                      caseReference: complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id,
                      initialSubject: '[MarineLink Admin] Official Notice: Case #${complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id}',
                      initialBody: 'Dear ${complaint.accusedName},\n\nA grievance has been registered regarding ${complaint.type} for order #${complaint.orderId ?? 'N/A'}.\n\nStatement: "${complaint.description}"\nCurrent Status: ${complaint.status}\n\nPlease review your MarineLink portal or reply to this notice immediately to maintain your compliant platform standing.\n\nRegards,\nMarineLink Compliance & Administration Team',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showValidationDialog(Complaint complaint) {
    String selectedStatus = complaint.status;
    if (selectedStatus.toLowerCase() == 'resolved') {
      selectedStatus = 'Completed';
    }
    if (!['Pending', 'Validated (Cheating Confirmed)', 'Completed', 'Dismissed'].contains(selectedStatus)) {
      selectedStatus = 'Validated (Cheating Confirmed)';
    }
    final remarksController = TextEditingController(text: complaint.adminRemarks ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xff0A4D68)),
                  const SizedBox(width: 8),
                  const Text('Admin Validation Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case #${complaint.id.length > 8 ? complaint.id.substring(0, 8) : complaint.id} - ${complaint.type}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Validation Verdict:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    _statusRadioOption(
                      title: 'Validated (Cheating Confirmed)',
                      subtitle: 'Violations or fraudulent claims confirmed. Warning/action enforced.',
                      color: Colors.red,
                      isSelected: selectedStatus == 'Validated (Cheating Confirmed)',
                      onTap: () => setDialogState(() => selectedStatus = 'Validated (Cheating Confirmed)'),
                    ),
                    _statusRadioOption(
                      title: 'Completed',
                      subtitle: 'Grievance settled and completed (refund or replacement resolved).',
                      color: Colors.green,
                      isSelected: selectedStatus == 'Completed',
                      onTap: () => setDialogState(() => selectedStatus = 'Completed'),
                    ),
                    _statusRadioOption(
                      title: 'Pending',
                      subtitle: 'Mark under ongoing investigation/review.',
                      color: Colors.orange.shade800,
                      isSelected: selectedStatus == 'Pending',
                      onTap: () => setDialogState(() => selectedStatus = 'Pending'),
                    ),
                    _statusRadioOption(
                      title: 'Dismissed',
                      subtitle: 'Complaint investigated and deemed invalid or lacking merit.',
                      color: Colors.grey,
                      isSelected: selectedStatus == 'Dismissed',
                      onTap: () => setDialogState(() => selectedStatus = 'Dismissed'),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Admin Findings & Enforcement Remarks:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),


                    TextField(
                      controller: remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter formal remarks, sanctions, or settlement terms...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentAdmin = FirebaseAuth.instance.currentUser;
                          final navigator = Navigator.of(dialogCtx);
                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() => isSaving = true);

                          final success = await _complaintService.validateComplaint(
                            complaintId: complaint.id,
                            newStatus: selectedStatus,
                            adminRemarks: remarksController.text.trim().isNotEmpty
                                ? remarksController.text.trim()
                                : 'Reviewed and verified by Administrator.',
                            adminId: currentAdmin?.uid ?? 'admin',
                            complaint: complaint,
                          );

                          navigator.pop();
                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Complaint verdict saved and notifications dispatched!'
                                    : 'Failed to update complaint status.',
                              ),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  child: Text(isSaving ? 'Saving...' : 'Apply Verdict'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusRadioOption({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
