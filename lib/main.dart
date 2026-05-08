import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  // Enable Firestore offline cache (works on both web + mobile in v5+).
  // Tasks, notes, subjects and alarms will load from local cache when offline
  // and queued writes sync automatically when connection is restored.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(StudentHubApp(isDarkMode: isDarkMode));
}

class StudentHubApp extends StatefulWidget {
  final bool isDarkMode;

  const StudentHubApp({super.key, required this.isDarkMode});

  @override
  State<StudentHubApp> createState() => _StudentHubAppState();
}

class _StudentHubAppState extends State<StudentHubApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Hub',

      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),

      // 🚀 First screen
      home: SplashScreen(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}