import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  const SplashScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _checkAuthState);
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user != null
              ? HomeScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)
              : LoginScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkMode ? kPrimaryGradientDark : kPrimaryGradient,
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Student Hub',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Your study companion',
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 48),
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
