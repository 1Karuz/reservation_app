// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/app_logger.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      if (ts is Timestamp) return ts.toDate();
      if (ts is Map && ts['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((ts['seconds'] as int) * 1000);
      }
      return DateTime.parse(ts.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  // Mark all notifications as read when leaving the page
  Future<void> _markAllAsRead() async {
  if (userId == null) {
    AppLogger.warning('Cannot mark notifications as read - no user ID', 'NOTIFICATIONS');
    return;
  }
  
  AppLogger.debug('Marking all notifications as read for user: $userId', 'NOTIFICATIONS');
  
  try {
    final query = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("read", isEqualTo: false)
        .get();

    AppLogger.debug('Found ${query.docs.length} unread notifications to mark as read', 'NOTIFICATIONS');

    for (var doc in query.docs) {
      await doc.reference.update({"read": true});
    }
    
    AppLogger.debug('Successfully marked all notifications as read', 'NOTIFICATIONS');
  } catch (e) {
    AppLogger.error('Failed to mark notifications as read', e, StackTrace.current, 'NOTIFICATIONS');
  }
}

  @override
  void dispose() {
    _markAllAsRead();
    super.dispose();
  }

  // Get status from notification message
  String _getNotificationStatus(String message) {
    if (message.toLowerCase().contains('approved')) {
      return 'approved';
    } else if (message.toLowerCase().contains('rejected')) {
      return 'rejected';
    } else if (message.toLowerCase().contains('deleted')) {
      return 'deleted';
    }
    return 'info';
  }

  // Parse rejection message to extract structured data
  Map<String, String?> _parseRejectionMessage(String message) {
    // Default structure
    Map<String, String?> result = {
      'title': 'Your reservation was rejected',
      'reason': null,
      'adminComment': null,
    };

    if (!message.toLowerCase().contains('rejected')) {
      return {'title': message, 'reason': null, 'adminComment': null};
    }

    // Debug print to see the actual message format
    debugPrint('Parsing message: $message');

    // Try to extract reason - handle both formats
    final reasonMatch = RegExp(r'Reason:\s*(.+?)(?:\s+Additional details:|$)', 
        caseSensitive: false, dotAll: true).firstMatch(message);
    
    if (reasonMatch != null) {
      result['reason'] = reasonMatch.group(1)?.trim();
    }

    // Try to extract additional details/comments
    final additionalMatch = RegExp(r'Additional details:\s*(.+)', 
        caseSensitive: false, dotAll: true).firstMatch(message);
    
    if (additionalMatch != null) {
      result['adminComment'] = additionalMatch.group(1)?.trim();
    }

    // If no structured format found, try alternative parsing
    if (result['reason'] == null) {
      // Try to extract everything after "rejected" as reason
      final altMatch = RegExp(r'rejected\.?\s*(.+)', 
          caseSensitive: false, dotAll: true).firstMatch(message);
      if (altMatch != null) {
        String fullReason = altMatch.group(1)?.trim() ?? '';
        
        // Check if there's "Additional details" in the full reason
        if (fullReason.toLowerCase().contains('additional details:')) {
          final parts = fullReason.split(RegExp(r'additional details:', caseSensitive: false));
          if (parts.length >= 2) {
            result['reason'] = parts[0].trim();
            result['adminComment'] = parts[1].trim();
          }
        } else {
          result['reason'] = fullReason;
        }
      }
    }

    debugPrint('Parsed result: $result');
    return result;
  }

  // Get reason icon based on rejection reason
  IconData _getReasonIcon(String? reason) {
    if (reason == null) return Icons.info_outline;
    
    final reasonLower = reason.toLowerCase();
    if (reasonLower.contains('conflict') || reasonLower.contains('date')) {
      return Icons.schedule_outlined;
    } else if (reasonLower.contains('incomplete') || reasonLower.contains('missing')) {
      return Icons.description_outlined;
    } else if (reasonLower.contains('invalid') || reasonLower.contains('expired')) {
      return Icons.error_outline;
    } else if (reasonLower.contains('capacity') || reasonLower.contains('exceeded')) {
      return Icons.groups_outlined;
    } else if (reasonLower.contains('policy') || reasonLower.contains('violation')) {
      return Icons.gavel_outlined;
    } else if (reasonLower.contains('advance') || reasonLower.contains('notice')) {
      return Icons.access_time_outlined;
    } else if (reasonLower.contains('payment')) {
      return Icons.payment_outlined;
    } else if (reasonLower.contains('maintenance')) {
      return Icons.build_outlined;
    } else if (reasonLower.contains('religious')) {
      return Icons.church_outlined;
    }
    return Icons.info_outline;
  }

  // Get container color based on status
  Color _getContainerColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade50;
      case 'rejected':
      case 'deleted':
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  // Get border color based on status
  Color _getBorderColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade200;
      case 'rejected':
      case 'deleted':
        return Colors.red.shade200;
      default:
        return Colors.blue.shade200;
    }
  }

  // Get icon based on status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'deleted':
        return Icons.delete;
      default:
        return Icons.notifications;
    }
  }

  // Get icon color based on status
  Color _getIconColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
      case 'deleted':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  // Build rejection notification with structured layout
  Widget _buildRejectionNotification(String message, String formattedDate, bool read) {
    final parsed = _parseRejectionMessage(message);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parsed['title'] ?? 'Reservation Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'REJECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason section
                if (parsed['reason'] != null && parsed['reason']!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getReasonIcon(parsed['reason']),
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parsed['reason']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Admin comment section
                if (parsed['adminComment'] != null && parsed['adminComment']!.isNotEmpty) ...[
                  if (parsed['reason'] != null && parsed['reason']!.isNotEmpty)
                    const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Comment',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                parsed['adminComment']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.3,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // If no structured data, show original message
                if ((parsed['reason'] == null || parsed['reason']!.isEmpty) &&
                    (parsed['adminComment'] == null || parsed['adminComment']!.isEmpty)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build regular notification
  Widget _buildRegularNotification(Map<String, dynamic> data, String formattedDate, String status) {
    final message = data['message'] ?? "No message";
    final read = data['read'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getContainerColor(status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(status),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Icon(
          _getStatusIcon(status),
          color: _getIconColor(status),
          size: 30,
        ),
        title: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            fontWeight: read ? FontWeight.w500 : FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: formattedDate.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            : null,
        trailing: status != 'info'
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getIconColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : !read
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (userId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Please log in to view notifications",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notifications")
          .where("userId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No notifications yet",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You'll see updates about your reservations here",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort notifications by timestamp
        final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        docs.sort((a, b) {
          final aTs = _parseTimestamp((a.data() as Map<String, dynamic>)['timestamp']);
          final bTs = _parseTimestamp((b.data() as Map<String, dynamic>)['timestamp']);
          return bTs.compareTo(aTs);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final message = data['message'] ?? "No message";
            final read = data['read'] ?? false;
            final ts = _parseTimestamp(data['timestamp']);
            final formattedDate = ts == DateTime.fromMillisecondsSinceEpoch(0)
                ? ''
                : DateFormat('MMM d, yyyy • HH:mm').format(ts);
            
            final status = _getNotificationStatus(message);

            // Use special layout for rejection notifications
            if (status == 'rejected') {
              return _buildRejectionNotification(message, formattedDate, read);
            } else {
              return _buildRegularNotification(data, formattedDate, status);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        title: Text(
          "Notifications",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildNotificationsList(),
    );
  }
}