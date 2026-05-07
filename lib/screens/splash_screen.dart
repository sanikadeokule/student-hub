import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // ⏳ Show splash for 2 seconds, then check auth state
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (!mounted) return;

      if (user != null) {
        // ✅ User is logged in → HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)),
        );
      } else {
        // ❌ User is not logged in → LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.network(
          "https://assets2.lottiefiles.com/packages/lf20_touohxv0.json",
        ),
      ),
    );
  }
}
