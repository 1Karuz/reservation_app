// pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../models/user_session.dart';
import '../widgets/event_card_widget.dart';
import 'reservation_page.dart';
import 'my_bookings_page.dart';
import 'auth_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
// Replace the events list in home_screen.dart with this:

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
    description: 'Honor and remember your loved one with dignity and respect.',
    imagePath: 'assets/images/funeral.jpg',
  ),
  EventCard(
    title: 'House Blessing',
    description: 'Welcome positivity into your new home with church blessings.',
    imagePath: 'assets/images/house_blessing.webp',
  ),
  EventCard(
    title: 'Ordination',
    description: 'Celebrate a sacred calling with reverence who will serve the lord.',
    imagePath: 'assets/images/ordination.jpg',
  ),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // title: const Text(
        //   'Chatbot integrated Reservation system a...',
        //   style: TextStyle(color: Colors.white, fontSize: 16),
        // ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildAppDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'EVENTS',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  // fontFamily: 'Terraria',
                  // fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 500,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    height: 500,
                    margin: const EdgeInsets.only(right: 20),
                    child: EventCardWidget(
                      event: events[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationPage(eventType: events[index].title),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildBookingMadeEasierSection(),
            const SizedBox(height: 40),
          ],
        ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyBookingsPage()),
                    );
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

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

// Replace the _buildBookingMadeEasierSection() method in home_screen.dart with this:

Widget _buildBookingMadeEasierSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const Text(
          'Booking made easier!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        // Bento grid layout with properly fitted images
        SizedBox(
          height: 300,
          child: Row(
            children: [
              // Left column - 2 small boxes
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10, bottom: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.asset(
                              'assets/images/grass.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '(grass image)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10, top: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.asset(
                              'assets/images/sky.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '(sky image)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right column - 2 boxes
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10, bottom: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                             child: Image.asset(
                              'assets/images/flowers.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '(flowers image)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10, top: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Image.asset(
                              'assets/images/bible.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '(bible image)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                'house blessings, and ordinations.'
              ),
              SizedBox(height: 10),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Easy event booking'),
              Text('• Reservation management'),
              Text('• User-friendly interface'),
              Text('• Secure authentication'),
              Text('\n\ncreated by: Jhon Kalvin Porteria et. al.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exitApp(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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

  void _logout(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                UserSession.clearSession();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}