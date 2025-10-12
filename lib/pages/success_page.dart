// pages/success_page.dart (Updated - Removed "Go Home, Pay Later" button)
import 'package:flutter/material.dart';
import 'payment_page.dart';
import '../services/app_logger.dart';

class SuccessPage extends StatelessWidget {
  final String eventType;
  final String name;
  final String email;
  final DateTime date;
  final String contact;
  final String timeFrom;
  final String timeTo;
  final String reservationId;

  const SuccessPage({
    super.key,
    required this.eventType,
    required this.name,
    required this.email,
    required this.date,
    required this.contact,
    required this.timeFrom,
    required this.timeTo,
    required this.reservationId,
  });

  String _getDisplayName() {
  switch (eventType.toLowerCase()) {
    case 'wedding':
      // Name is already formatted as "Groom & Bride" from reservation_page
      return name;
    case 'baptism':
      return name; // Child's name
    case 'funeral':
      return name; // Deceased's name
    case 'house blessing':
      return name; // Homeowner's name
    case 'confession':
      return name; // Person's name
    default:
      return name;
  }
}

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Success page displayed for event: $eventType');

    final serviceColor = _getServiceColor(eventType);
    final serviceIcon = _getServiceIcon(eventType);

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reservation Confirmed!',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width:
                MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Success Card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Icon with Service Color
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              serviceColor.withOpacity(0.8),
                              serviceColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: serviceColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Reservation Confirmed!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your ${eventType.toLowerCase()} has been successfully reserved',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Reservation Details Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: serviceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              serviceIcon,
                              color: serviceColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reservation Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  eventType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: serviceColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildModernInfoRow(
                                'Name', _getDisplayName(), Icons.person),
                            _buildModernInfoRow('Email', email, Icons.email),
                            _buildModernInfoRow(
                                'Date',
                                date.toLocal().toString().split(' ')[0],
                                Icons.calendar_today),
                            _buildModernInfoRow('Time', '$timeFrom - $timeTo',
                                Icons.access_time),
                            _buildModernInfoRow(
                                'Contact', contact, Icons.phone),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Important Note
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please proceed to payment to complete your reservation process.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Single Action Button - Proceed to Payment Only
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [serviceColor.withOpacity(0.8), serviceColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: serviceColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      AppLogger.ui('User proceeding to payment page');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            eventType: eventType,
                            name: name,
                            email: email,
                            date: date,
                            contact: contact,
                            timeFrom: timeFrom,
                            timeTo: timeTo,
                            reservationId: reservationId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return const Color(0xFFE91E63);
      case 'baptism':
        return const Color(0xFF2196F3);
      case 'funeral':
        return const Color(0xFF757575);
      case 'house blessing':
        return const Color(0xFF4CAF50);
      case 'confession':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getServiceIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'baptism':
        return Icons.water_drop;
      case 'funeral':
        return Icons.local_florist;
      case 'house blessing':
        return Icons.home;
      case 'confession':
        return Icons.auto_stories;
      default:
        return Icons.event;
    }
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.grey[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
