// pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event_model.dart';
import '../models/user_session.dart';
import '../widgets/event_card_widget.dart';
import 'reservation_page.dart';
import 'my_bookings_page.dart';
import 'auth_page.dart';
import '/pages/notification_page.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _showAllEvents = false;
  late AnimationController _calendarController;
  late AnimationController _statsController;
  late Animation<double> _calendarAnimation;
  late Animation<double> _statsAnimation;
  
  // Add StreamSubscription to properly manage listeners
  StreamSubscription<QuerySnapshot>? _reservationsSubscription;
  bool _isDisposed = false;

  final List<EventCard> events = const [
    EventCard(
      title: 'Wedding',
      description: 'Celebrate your special day with elegance and love with us.',
      imagePath: 'assets/images/wedding.jpg',
    ),
    EventCard(
      title: 'Baptism',
      description: 'Mark the beginning of a blessed journey with your baby.',
      imagePath: 'assets/images/baptism.jpg',
    ),
    EventCard(
      title: 'Funeral',
      description:
          'Honor and remember your loved one with dignity and respect.',
      imagePath: 'assets/images/funeral.jpg',
    ),
    EventCard(
      title: 'House Blessing',
      description:
          'Welcome positivity into your new home with church blessings.',
      imagePath: 'assets/images/house_blessing.webp',
    ),
    EventCard(
      title: 'Ordination',
      description:
          'Celebrate a sacred calling with reverence who will serve the lord.',
      imagePath: 'assets/images/ordination.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();

    // Animation controllers
    _calendarController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _calendarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _calendarController, curve: Curves.easeInOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeInOut),
    );

    // Start animations
    _calendarController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _statsController.forward();
      }
    });

    _loadReservations();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel the subscription before disposing
    _reservationsSubscription?.cancel();
    
    // Dispose animation controllers
    _calendarController.dispose();
    _statsController.dispose();
    
    super.dispose();
  }

  void _loadReservations() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cancel existing subscription
    _reservationsSubscription?.cancel();

    _reservationsSubscription = FirebaseFirestore.instance
        .collection("reservations")
        .where(_showAllEvents ? "status" : "userId",
            isEqualTo: _showAllEvents ? "approved" : userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (_isDisposed) return; // Check if widget is disposed
            
            Map<DateTime, List<dynamic>> events = {};

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final date = _parseFirebaseDate(data['date']);
              if (date != null) {
                final eventDate = DateTime(date.year, date.month, date.day);
                if (events[eventDate] == null) events[eventDate] = [];
                events[eventDate]!.add({
                  'id': doc.id,
                  'eventType': data['eventType'] ?? 'Event',
                  'timeFrom': data['timeFrom'] ?? '',
                  'timeTo': data['timeTo'] ?? '',
                  'name': data['name'] ?? 'Unknown',
                  'status': data['status'] ?? 'pending',
                  'isOwn': data['userId'] == userId,
                });
              }
            }

            if (mounted && !_isDisposed) {
              setState(() {
                _events = events;
              });
            }
          },
          onError: (error) {
            if (mounted && !_isDisposed) {
              debugPrint('Error loading reservations: $error');
            }
          },
        );
  }

  DateTime? _parseFirebaseDate(dynamic dateField) {
    if (dateField == null) return null;
    try {
      if (dateField is Timestamp) return dateField.toDate();
      if (dateField is Map && dateField['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(dateField['seconds'] * 1000);
      }
      if (dateField is String) return DateTime.parse(dateField);
      return DateTime.fromMillisecondsSinceEpoch(dateField);
    } catch (e) {
      return null;
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (userId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("userId", isEqualTo: userId)
                  .where("read", isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
                  );
                }

                int unreadCount = snapshot.data!.docs.length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                        }
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      drawer: _buildAppDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.grey],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'EVENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create unforgettable moments',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Event Cards
                  SizedBox(
                    height: 480,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 300,
                          height: 480,
                          margin: const EdgeInsets.only(right: 20),
                          child: EventCardWidget(
                            event: events[index],
                            onTap: () {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationPage(
                                        eventType: events[index].title),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Quick Stats Section
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _statsAnimation.value,
                  child: Opacity(
                    opacity: _statsAnimation.value,
                    child: _buildQuickStatsSection(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Booking Made Easier Section with Calendar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Booking made easier!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'View available dates and plan your perfect event',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // Modern Calendar Section
            AnimatedBuilder(
              animation: _calendarAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _calendarAnimation.value)),
                  child: Opacity(
                    opacity: _calendarAnimation.value,
                    child: _buildModernCalendarSection(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Features Section
            _buildFeaturesSection(),

            const SizedBox(height: 40),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("reservations").snapshots(),
      builder: (context, snapshot) {
        int totalReservations = 0;
        int approvedReservations = 0;
        int pendingReservations = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalReservations++;
            final status = doc.data() as Map<String, dynamic>;
            if (status['status'] == 'approved') approvedReservations++;
            if (status['status'] == 'pending') pendingReservations++;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.black, Color.fromARGB(255, 197, 197, 197)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  Icons.event_available, 'Total\nEvents', '$totalReservations'),
              _buildStatItem(
                  Icons.check_circle, 'Approved', '$approvedReservations'),
              _buildStatItem(Icons.schedule, 'Pending', '$pendingReservations'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.grey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Event Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (mounted && !_isDisposed) {
                          setState(() {
                            _showAllEvents = !_showAllEvents;
                          });
                          _loadReservations();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showAllEvents
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showAllEvents
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _showAllEvents ? 'All Events' : 'My Events',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TableCalendar<dynamic>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
                selectedDecoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue[300],
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.orange[400],
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.indigo),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.indigo),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!mounted || _isDisposed) return;
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                if (!_isDisposed) {
                  _focusedDay = focusedDay;
                }
              },
            ),
          ),

          // Events for selected day
          if (_selectedDay != null &&
              _getEventsForDay(_selectedDay!).isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(_getEventsForDay(_selectedDay!)
                      .take(3)
                      .map((event) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: event['isOwn']
                                  ? Colors.blue[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: event['isOwn']
                                    ? Colors.blue[200]!
                                    : Colors.orange[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  event['isOwn'] ? Icons.person : Icons.group,
                                  size: 16,
                                  color: event['isOwn']
                                      ? Colors.blue[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['eventType'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: event['isOwn']
                                              ? Colors.blue[800]
                                              : Colors.orange[800],
                                        ),
                                      ),
                                      Text(
                                        '${event['timeFrom']} - ${event['timeTo']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(event['status']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    event['status'].toString().toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList()),
                ],
              ),
            ),
        ],
      ),
    );
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

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.schedule,
        'title': 'Flexible Scheduling',
        'description': 'Book events at your preferred time and date',
        'color': Colors.blue,
      },
      {
        'icon': Icons.verified,
        'title': 'Instant Confirmation',
        'description': 'Get immediate booking confirmations',
        'color': Colors.green,
      },
      {
        'icon': Icons.support_agent,
        'title': '24/7 Support',
        'description': 'Round-the-clock assistance for your events',
        'color': Colors.orange,
      },
      {
        'icon': Icons.security,
        'title': 'Secure Booking',
        'description': 'Your data and reservations are always safe',
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Why Choose Us?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: feature['color'] as Color,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 40,
                      color: feature['color'] as Color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  'Home',
                  Icons.home,
                  () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context,
                  'My Bookings',
                  Icons.book,
                  () {
                    Navigator.pop(context);
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyBookingsPage()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  'About',
                  Icons.info,
                  () => _showAboutDialog(context),
                ),
                _buildDrawerItem(
                  context,
                  'Quit',
                  Icons.exit_to_app,
                  () => _exitApp(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
                _buildDrawerItem(
                  context,
                  'Log out',
                  Icons.logout,
                  () => _logout(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${UserSession.email}!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('About'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Reservation System',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text('Version: 1.0.0'),
                SizedBox(height: 10),
                Text(
                    'This app is designed to make event reservations easier and more convenient. '
                    'You can book various types of events including weddings, baptisms, funerals, '
                    'house blessings, and ordinations.'),
                SizedBox(height: 10),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Easy event booking'),
                Text('• Reservation management'),
                Text('• User-friendly interface'),
                Text('• Secure authentication'),
                Text('• Calendar overview'),
                Text('\n\ncreated by: Jhon Kalvin Porteria et. al.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _exitApp(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit'),
              ),
            ],
          );
        },
      );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Store context references before async operations
                  final navigator = Navigator.of(dialogContext);
                  
                  try {
                    // Clear user session first
                    UserSession.clearSession();
                    
                    // Sign out from Firebase
                    await FirebaseAuth.instance.signOut();
                    
                    // Navigate only if widget is still mounted
                    if (mounted) {
                      navigator.pop(); // Close dialog
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    }
  }
}