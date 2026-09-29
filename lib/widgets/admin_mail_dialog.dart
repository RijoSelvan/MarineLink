import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';

class AdminMailDialog {
  /// Opens a versatile mailing dialog for the Admin to email and message
  /// any buyer, exporter, or complaint participant.
  static void show({
    required BuildContext context,
    required String recipientName,
    required String recipientEmail,
    required String recipientRole, // 'Buyer', 'Exporter', etc.
    String? recipientUserId,
    String? initialSubject,
    String? initialBody,
    String? caseReference,
  }) {
    final TextEditingController emailController =
        TextEditingController(text: recipientEmail);
    final TextEditingController subjectController = TextEditingController(
      text: initialSubject ??
          (caseReference != null && caseReference.isNotEmpty
              ? '[MarineLink Admin] Notice: Case #$caseReference'
              : '[MarineLink Admin] Official Communication'),
    );
    final TextEditingController bodyController = TextEditingController(
      text: initialBody ??
          'Dear $recipientName,\n\nWe are contacting you from MarineLink Administration regarding your account activity.\n\nPlease review and let us know if you have any questions.\n\nRegards,\nMarineLink Administration Team',
    );

    bool isSendingNotice = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff0A4D68).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xff0A4D68),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Official Mail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$recipientName ($recipientRole)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient Email field
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Recipient Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subject field
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          prefixIcon:
                              const Icon(Icons.subject_outlined, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message Body field
                      TextField(
                        controller: bodyController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Message Body',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action tips
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xff0A4D68)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can launch your device mail app (Gmail/Outlook) or dispatch an in-app priority notice directly to this $recipientRole.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff0A4D68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Copy button
                TextButton.icon(
                  onPressed: () {
                    final fullText =
                        'To: ${emailController.text}\nSubject: ${subjectController.text}\n\n${bodyController.text}';
                    Clipboard.setData(ClipboardData(text: fullText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email details copied to clipboard! 📋'),
                        backgroundColor: Colors.blueGrey,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),

                // In-App Notice Button
                if (recipientUserId != null && recipientUserId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: isSendingNotice
                        ? null
                        : () async {
                            setDialogState(() => isSendingNotice = true);
                            try {
                              final notif = NotificationService();
                              await notif.notifyUser(
                                userId: recipientUserId,
                                title: subjectController.text.trim(),
                                message: bodyController.text.trim(),
                                type: 'admin_official_notice',
                              );

                              // Log to admin_communications
                              await FirebaseFirestore.instance
                                  .collection('admin_communications')
                                  .add({
                                'recipientId': recipientUserId,
                                'recipientName': recipientName,
                                'recipientEmail': emailController.text.trim(),
                                'recipientRole': recipientRole,
                                'subject': subjectController.text.trim(),
                                'body': bodyController.text.trim(),
                                'caseReference': caseReference ?? '',
                                'channel': 'in_app_notice',
                                'sentAt': FieldValue.serverTimestamp(),
                              });

                              if (!ctx.mounted) return;
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'In-app notice dispatched to $recipientName! 🔔',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() => isSendingNotice = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to send notice: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: isSendingNotice
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined,
                            size: 16),
                    label: const Text('In-App Notice'),
                  ),

                // Open Mail App (mailto:)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4D68),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final targetEmail = emailController.text.trim();
                    final subject = subjectController.text.trim();
                    final body = bodyController.text.trim();

                    if (targetEmail.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please specify a valid email address'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Log communication to Firestore
                    try {
                      await FirebaseFirestore.instance
                          .collection('admin_communications')
                          .add({
                        'recipientId': recipientUserId ?? '',
                        'recipientName': recipientName,
                        'recipientEmail': targetEmail,
                        'recipientRole': recipientRole,
                        'subject': subject,
                        'body': body,
                        'caseReference': caseReference ?? '',
                        'channel': 'email',
                        'sentAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {}

                    final Uri mailUri = Uri(
                      scheme: 'mailto',
                      path: targetEmail,
                      queryParameters: {
                        'subject': subject,
                        'body': body,
                      },
                    );

                    try {
                      final bool launched = await launchUrl(
                        mailUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched) {
                        // Fallback: copy to clipboard
                        Clipboard.setData(ClipboardData(
                          text: 'To: $targetEmail\nSubject: $subject\n\n$body',
                        ));
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not open mail app directly. Email details copied to clipboard!',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (err) {
                      Clipboard.setData(ClipboardData(
                        text: 'To: $targetEmail\nSubject: $subject\n\n$body',
                      ));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email copied to clipboard (Error: $err)'),
                          backgroundColor: Colors.blueGrey,
                        ),
                      );
                    }

                    if (ctx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Open Mail App'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
