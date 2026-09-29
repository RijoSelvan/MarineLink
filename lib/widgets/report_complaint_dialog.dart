import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ReportComplaintDialog extends StatefulWidget {
  final String? orderId;
  final String? fishName;
  final String? accusedId;
  final String accusedName;
  final String accusedRole; // 'Exporter' or 'Buyer'
  final String userRole; // 'Buyer' or 'Exporter'

  const ReportComplaintDialog({
    super.key,
    this.orderId,
    this.fishName,
    this.accusedId,
    required this.accusedName,
    required this.accusedRole,
    required this.userRole,
  });

  static Future<void> show(
    BuildContext context, {
    String? orderId,
    String? fishName,
    String? accusedId,
    required String accusedName,
    required String accusedRole,
    required String userRole,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReportComplaintDialog(
        orderId: orderId,
        fishName: fishName,
        accusedId: accusedId,
        accusedName: accusedName,
        accusedRole: accusedRole,
        userRole: userRole,
      ),
    );
  }

  @override
  State<ReportComplaintDialog> createState() => _ReportComplaintDialogState();
}

class _ReportComplaintDialogState extends State<ReportComplaintDialog> {
  final TextEditingController _descController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();

  String _selectedType = 'Cheating / Fraud';
  bool _isSubmitting = false;

  final List<String> _types = const [
    'Cheating / Fraud',
    'Spoiled / Poor Quality Fish',
    'Weight Discrepancy',
    'Payment Dispute',
    'Transit / Packaging Damage',
    'Non-Delivery / False Delivery Claim',
    'Unfair Pricing / Overcharge',
    'Other Issue',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _descController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the cheating or grievance in detail.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final complaint = Complaint(
      id: '',
      orderId: widget.orderId,
      fishName: widget.fishName,
      complaintBy: user.uid,
      complaintByName: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'User'),
      complaintByEmail: user.email ?? '',
      complaintByRole: widget.userRole,
      accusedId: widget.accusedId,
      accusedName: widget.accusedName,
      accusedRole: widget.accusedRole,
      type: _selectedType,
      description: text,
      status: 'Pending',
      createdAt: DateTime.now(),
    );

    final result = await _complaintService.submitComplaint(complaint);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('Complaint Lodged'),
            ],
          ),
          content: const Text(
            'Your grievance has been submitted directly to the Admin portal.\n\nAdmin will investigate the transaction and validate any cheating or quality non-compliance.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4D68),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit complaint. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Report Issue to Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF4F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${widget.accusedName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff0A4D68).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.accusedRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0A4D68),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.orderId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order #${widget.orderId!.length > 12 ? widget.orderId!.substring(0, 12) : widget.orderId}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                  if (widget.fishName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Item: ${widget.fishName}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Complaint Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),

            const SizedBox(height: 14),

            const Text(
              'Describe the Problem / Cheating',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Provide specific details (e.g. delivered product was thawed, wrong weight, refused delivery, false payment claim)...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit to Admin'),
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
