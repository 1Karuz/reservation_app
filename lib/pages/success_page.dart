// pages/success_page.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SuccessPage extends StatelessWidget {
final String eventType;
final String name;
final String email;
final DateTime date;
final String contact;
final String timeFrom;
final String timeTo;

  const SuccessPage({
    super.key,
    required this.eventType,
    required this.name,
    required this.email,
    required this.date,
    required this.contact,
    required this.timeFrom,
    required this.timeTo,
  });

  String _getServiceTagline(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return "Your wedding ceremony is confirmed. The customary church stipend for the sacrament of Matrimony is approximately ₱5,000 - ₱12,000. Please coordinate with the parish office to finalize this offering and any additional arrangements.";
      case 'baptism':
        return "Your child's Baptism is reserved. A customary donation of around ₱400 - ₱2,500 for the church's ministry is appreciated. Kindly be ready to offer this stipend at the parish office on the day of the baptism.";
      case 'funeral':
        return "We are sorry for your loss. The funeral mass has been arranged. A stipend of approximately ₱1,000 - ₱5,000 for the celebrant and church is customary. Please settle this at the parish office at your convenience.";
      case 'house blessing':
        return "Your house blessing is scheduled. The customary stipend for the priest's ministry is typically ₱1,000 - ₱3,000. Please prepare this offering for him after the blessing ceremony.";
      case 'confession':
        return "Your time for the Sacrament of Reconciliation is reserved. Please note that confession is a gift of grace and has no required fee. A voluntary donation to support the church's ministry is always welcome but entirely optional.";
      default:
        return "Your reservation has been confirmed. Please contact the parish office for any additional information regarding customary donations or arrangements.";
    }
  }

  Color _getServiceColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return const Color(0xFFE91E63); // Pink for wedding
      case 'baptism':
        return const Color(0xFF2196F3); // Blue for baptism
      case 'funeral':
        return const Color(0xFF757575); // Grey for funeral
      case 'house blessing':
        return const Color(0xFF4CAF50); // Green for house blessing
      case 'confession':
        return const Color(0xFF9C27B0); // Purple for confession
      default:
        return const Color(0xFF607D8B); // Blue grey default
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

  @override
  Widget build(BuildContext context) {
    final serviceColor = _getServiceColor(eventType);
    final serviceIcon = _getServiceIcon(eventType);
    final tagline = _getServiceTagline(eventType);

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reservation Confirmed!',
          style: TextStyle(color: Colors.white),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
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
                      const SizedBox(height: 10),
                      const Text(
                        'Kindly wait for admin approval',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Service Information Card
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
                            _buildModernInfoRow('Name', name, Icons.person),
                            _buildModernInfoRow('Email', email, Icons.email),
                            _buildModernInfoRow('Date', date.toLocal().toString().split(' ')[0], Icons.calendar_today),
                            _buildModernInfoRow('Time', '$timeFrom - $timeTo', Icons.access_time),
                            _buildModernInfoRow('Contact', contact, Icons.phone),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Service Tagline Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        serviceColor.withOpacity(0.05),
                        serviceColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: serviceColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: serviceColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: serviceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: serviceColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          tagline,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Go Home Button
                Container(
                  width: 200,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [serviceColor.withOpacity(0.8), serviceColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Go Home',
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