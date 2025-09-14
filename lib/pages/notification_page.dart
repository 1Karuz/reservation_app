// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    if (userId == null) return;
    final query = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("read", isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({"read": true});
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
                leading: Icon( // Changed from Container to just Icon
                  _getStatusIcon(status),
                  color: _getIconColor(status),
                  size: 30, // Slightly larger size
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