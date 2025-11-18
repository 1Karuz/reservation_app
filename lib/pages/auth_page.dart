// pages/auth_page.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../models/user_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_logger.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignUp = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
@override
Widget build(BuildContext context) {
  return Scaffold(
   body: Stack(
  children: [
    // Background image
    Positioned.fill(
      child: Image.asset(
        "assets/images/church.jpg",
        fit: BoxFit.cover,
      ),
    ),
    // Semi-transparent overlay
    Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6), 
      ),
    ),
    // Logo at top left
    Positioned(
      top: 50,
      left: 25,
      child: Image.asset(
        'assets/icons/logo.png',
        width: 70,
        height: 70,
      ),
    ),
    // Welcome banner at the top center
    Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: [
            Text(
              'Welcome to',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Sta. Ursula Reservation App!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
    // Login form
    Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(45),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSignUp ? 'Sign up' : 'Log in',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              if (isSignUp) ...[
                const SizedBox(height: 15),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              SizedBox(
                width: 125,
                child: ElevatedButton(
                  onPressed: _handleAuthentication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(isSignUp ? 'Sign Up' : 'Log in'),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignUp
                        ? 'Already have an account? '
                        : 'Don\'t have an account? ',
                    style: const TextStyle(color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isSignUp = !isSignUp;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      isSignUp ? 'Log in' : 'Sign up',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
  );
}


 void _handleAuthentication() async {
  if (_formKey.currentState!.validate()) {
    final email = emailController.text.trim();
    AppLogger.auth('Attempting ${isSignUp ? "sign up" : "sign in"} for email: $email');
    
    try {
      if (isSignUp) {
        AppLogger.auth('Creating new user account');
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: passwordController.text.trim(),
        );

        if (!mounted) return;
        
        AppLogger.auth('Account created successfully for: $email');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please log in.")),
        );

        setState(() {
          isSignUp = false;
        });
      } else {
        AppLogger.auth('Signing in user');
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwordController.text.trim(),
        );

        if (!mounted) return;

        AppLogger.auth('Sign in successful for: $email');
        UserSession.setemail(userCredential.user?.email ?? '');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
        AppLogger.auth('Sign in failed - user not found: $email');
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
        AppLogger.auth('Sign in failed - wrong password for: $email');
      } else if (e.code == 'email-already-in-use') {
        message = 'That email is already registered.';
        AppLogger.auth('Sign up failed - email already in use: $email');
      } else {
        message = e.message ?? 'Authentication failed';
        AppLogger.auth('Authentication failed with code: ${e.code}', e);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      AppLogger.error('Unexpected authentication error', e, StackTrace.current, 'AUTH');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
        );
      }
    }
  }
}

}
