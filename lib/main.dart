// main.dart
import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'pages/home_screen.dart';
import 'screens/onboarding_screen.dart'; // Import your custom onboarding screen
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_session.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EventReservationApp());
}

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
      home: const AuthStateManager(),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthStateManager extends StatefulWidget {
  const AuthStateManager({super.key});

  @override
  State<AuthStateManager> createState() => _AuthStateManagerState();
}

class _AuthStateManagerState extends State<AuthStateManager> {
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _isLoading = true;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if first time
      _isFirstTime = await _checkFirstTime();
      
      // If first time, don't set up auth listener yet
      if (_isFirstTime) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Set up auth state listener
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (User? user) {
          if (mounted) {
            setState(() {
              _currentUser = user;
              _isLoading = false;
            });
            
            // Update user session
            if (user != null) {
              UserSession.setemail(user.email ?? '');
            } else {
              UserSession.clearSession();
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _currentUser = null;
              _isLoading = false;
            });
            UserSession.clearSession();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkFirstTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('first_time') ?? true;
    } catch (e) {
      return true;
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isFirstTime) {
      // Use your custom onboarding screen
      return const OnboardingScreen();
    }

    if (_currentUser != null) {
      return const HomeScreen();
    }

    return const AuthPage();
  }
}