// main.dart
import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EventReservationApp());
}

// void main() {
//   runApp(const EventReservationApp());
// }

class EventReservationApp extends StatelessWidget {
  const EventReservationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Reservation System',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
      ),
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}