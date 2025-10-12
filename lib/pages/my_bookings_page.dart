// pages/my_bookings_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_logger.dart';
import '../models/user_session.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.debug('My Bookings page initialized', 'MY_BOOKINGS');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'My Reservations',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Track and manage your event bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),

            // Reservations List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reservations')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    AppLogger.error('Error loading user reservations',
                        snapshot.error, StackTrace.current, 'MY_BOOKINGS');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading reservations',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    AppLogger.debug('Loading user reservations', 'MY_BOOKINGS');
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.black,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading reservations...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    AppLogger.debug(
                        'No reservations found for user', 'MY_BOOKINGS');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No reservations found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Start by booking your first event!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final reservations = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ReservationData.fromFirestore(data, doc.id);
                  }).toList();

                  AppLogger.debug(
                      'Loaded ${reservations.length} reservations for user',
                      'MY_BOOKINGS');

                  return ListView.builder(
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          _getEventColor(reservation.eventType)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getEventIcon(reservation.eventType),
                                      color:
                                          _getEventColor(reservation.eventType),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reservation.eventType,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Created ${_formatDate(reservation.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  _buildStatusBadge(reservation.status),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Event-specific details
                              ..._buildEventSpecificDetails(reservation),

                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.calendar_today_outlined,
                                'Date',
                                reservation.date
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                              ),
                              _buildDetailRow(
                                Icons.access_time_outlined,
                                'Time',
                                '${reservation.timeFrom} - ${reservation.timeTo}',
                              ),
                              _buildDetailRow(Icons.phone_outlined, 'Contact',
                                  reservation.contact),

                              // Payment Status (if exists)
                              if (reservation.paymentStatus != null)
                                _buildPaymentStatusSection(reservation),

                              // Comments (if any)
                              if (reservation.comments.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow(Icons.message_outlined,
                                    'Comments', reservation.comments),
                              ],

                              // Delete button for pending reservations
                              if (reservation.status == "pending") ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          _deleteReservation(reservation),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        backgroundColor:
                                            Colors.red.withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build event-specific detail rows
  List<Widget> _buildEventSpecificDetails(ReservationData reservation) {
    switch (reservation.eventType.toLowerCase()) {
      case 'wedding':
        return [
          _buildDetailRow(Icons.male, 'Groom', reservation.groomName ?? '-'),
          _buildDetailRow(Icons.female, 'Bride', reservation.brideName ?? '-'),
          if (reservation.groomFather != null)
            _buildDetailRow(Icons.person_outline, 'Groom\'s Father',
                reservation.groomFather!),
          if (reservation.groomMother != null)
            _buildDetailRow(Icons.person_outline, 'Groom\'s Mother',
                reservation.groomMother!),
          if (reservation.brideFather != null)
            _buildDetailRow(Icons.person_outline, 'Bride\'s Father',
                reservation.brideFather!),
          if (reservation.brideMother != null)
            _buildDetailRow(Icons.person_outline, 'Bride\'s Mother',
                reservation.brideMother!),
        ];

      case 'baptism':
        return [
          _buildDetailRow(
              Icons.child_care, 'Child', reservation.childName ?? '-'),
          if (reservation.childBirthdate != null)
            _buildDetailRow(
                Icons.cake, 'Birth Date', reservation.childBirthdate!),
          if (reservation.childBirthplace != null)
            _buildDetailRow(
                Icons.location_on, 'Birth Place', reservation.childBirthplace!),
          if (reservation.fatherName != null)
            _buildDetailRow(Icons.person, 'Father', reservation.fatherName!),
          if (reservation.motherMaidenName != null)
            _buildDetailRow(
                Icons.person, 'Mother', reservation.motherMaidenName!),
          if (reservation.parentMarriageType != null)
            _buildDetailRow(Icons.favorite, 'Parents Marriage',
                reservation.parentMarriageType!),
          if (reservation.sponsors != null)
            _buildDetailRow(Icons.groups, 'Sponsors', reservation.sponsors!),
        ];

      case 'funeral':
        return [
          _buildDetailRow(
              Icons.person, 'Deceased', reservation.deceasedName ?? '-'),
          if (reservation.deceasedAge != null)
            _buildDetailRow(
                Icons.calendar_today, 'Age', reservation.deceasedAge!),
          if (reservation.deathDate != null)
            _buildDetailRow(
                Icons.event, 'Date of Death', reservation.deathDate!),
          if (reservation.burialDate != null)
            _buildDetailRow(
                Icons.event_available, 'Date Buried', reservation.burialDate!),
          if (reservation.residence != null)
            _buildDetailRow(Icons.home, 'Residence', reservation.residence!),
          if (reservation.causeOfDeath != null)
            _buildDetailRow(Icons.medical_services, 'Cause of Death',
                reservation.causeOfDeath!),
          if (reservation.guardianName != null)
            _buildDetailRow(Icons.supervisor_account, 'Guardian',
                reservation.guardianName!),
          if (reservation.burialPlace != null)
            _buildDetailRow(
                Icons.place, 'Burial Place', reservation.burialPlace!),
          if (reservation.wasBaptized != null)
            _buildDetailRow(Icons.church, 'Was Baptized',
                reservation.wasBaptized! ? 'Yes' : 'No'),
          if (reservation.receivedLastSacrament != null)
            _buildDetailRow(Icons.volunteer_activism, 'Last Sacrament',
                reservation.receivedLastSacrament! ? 'Yes' : 'No'),
        ];

      case 'house blessing':
        return [
          _buildDetailRow(Icons.person, 'Homeowner',
              reservation.homeownerName ?? reservation.name),
          if (reservation.houseAddress != null)
            _buildDetailRow(Icons.home, 'Address', reservation.houseAddress!),
        ];

      case 'confession':
        return [
          _buildDetailRow(
              Icons.person, 'Name', reservation.personName ?? reservation.name),
          if (reservation.notes != null && reservation.notes!.isNotEmpty)
            _buildDetailRow(Icons.note, 'Notes', reservation.notes!),
        ];

      default:
        return [
          _buildDetailRow(Icons.person_outline, 'Name', reservation.name),
          _buildDetailRow(Icons.email_outlined, 'Email', reservation.email),
        ];
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSection(ReservationData reservation) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _getPaymentStatusColor(reservation.paymentStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getPaymentStatusColor(reservation.paymentStatus)
              .withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPaymentStatusIcon(reservation.paymentStatus),
                color: _getPaymentStatusColor(reservation.paymentStatus),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getPaymentStatusColor(reservation.paymentStatus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPaymentStatusText(reservation.paymentStatus),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          if (reservation.paymentAmount != null &&
              reservation.paymentAmount! > 0)
            Text(
              'Amount: ₱${reservation.paymentAmount!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          if (reservation.paymentSubmittedAt != null)
            Text(
              'Submitted: ${_formatDate(reservation.paymentSubmittedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid_online':
        return 'Payment submitted online - awaiting admin verification';
      case 'pay_at_church':
        return 'Payment will be made at the church';
      case 'verified':
        return 'Payment verified by admin';
      case 'payment_pending':
        return 'Payment verification pending';
      default:
        return 'No payment information available';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid_online':
      case 'payment_pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'pay_at_church':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String? status) {
    switch (status) {
      case 'paid_online':
      case 'payment_pending':
        return Icons.pending_actions;
      case 'verified':
        return Icons.verified;
      case 'pay_at_church':
        return Icons.church;
      default:
        return Icons.payment_outlined;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120, // Fixed width for labels to prevent wrapping
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'funeral':
        return Icons.local_florist;
      case 'baptism':
        return Icons.child_care;
      case 'house blessing':
        return Icons.home;
      case 'confession':
        return Icons.church;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Colors.pink;
      case 'funeral':
        return Colors.purple;
      case 'baptism':
        return Colors.blue;
      case 'house blessing':
        return Colors.orange;
      case 'confession':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[600]!;
      default:
        return Colors.orange[600]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _deleteReservation(ReservationData reservation) async {
    AppLogger.debug(
        'User initiated reservation deletion: ${reservation.reservationId}',
        'MY_BOOKINGS');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Reservation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content:
              const Text('Are you sure you want to delete this reservation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                AppLogger.info(
                    'Deleting reservation: ${reservation.reservationId}',
                    'MY_BOOKINGS');

                try {
                  await FirebaseFirestore.instance
                      .collection('reservations')
                      .doc(reservation.reservationId)
                      .delete();

                  AppLogger.info(
                      'Successfully deleted reservation: ${reservation.reservationId}',
                      'MY_BOOKINGS');

                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Reservation deleted successfully'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  AppLogger.error(
                      'Failed to delete reservation: ${reservation.reservationId}',
                      e,
                      StackTrace.current,
                      'MY_BOOKINGS');
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Failed to delete reservation. Please try again.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
