import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:student_companion/screens/multimedia_screen.dart';
import 'package:student_companion/screens/image_transform_screen.dart';
import 'package:student_companion/screens/time_picker_screen.dart';
import 'package:student_companion/screens/notes_screen.dart';
import 'package:student_companion/screens/calculator_screen.dart';
import 'package:student_companion/screens/chatbot_screen.dart';
import 'package:student_companion/screens/task_list_screen.dart';
import 'package:student_companion/screens/analytics_screen.dart';
import 'package:student_companion/screens/subject_list_screen.dart';
import 'alarm_audio_stub.dart' if (dart.library.js_interop) 'alarm_audio_web.dart';

import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  // ── Alarm watcher ──────────────────────────────────────────────
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];
  StreamSubscription<List<AlarmModel>>? _alarmSub;
  Timer? _alarmTimer;
  final Set<String> _ringing = {};

  @override
  void initState() {
    super.initState();
    _alarmSub = _alarmService.getAlarms().listen((list) => _alarms = list);
    _alarmTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _checkAlarms());
    requestNotificationPermission();
  }

  @override
  void dispose() {
    _alarmSub?.cancel();
    _alarmTimer?.cancel();
    stopAlarmSound();
    super.dispose();
  }

  void _checkAlarms() {
    if (!mounted) return;
    final now = DateTime.now();
    for (final alarm in _alarms) {
      if (alarm.isActive &&
          !alarm.hasFired &&
          now.isAfter(alarm.dateTime) &&
          !_ringing.contains(alarm.id)) {
        _ringing.add(alarm.id);
        _alarmService.updateAlarm(alarm.id, isActive: false, hasFired: true);
        _fireAlarm(alarm);
        break;
      }
    }
  }

  void _fireAlarm(AlarmModel alarm) {
    playAlarmSound();
    showBrowserNotification(
        alarm.name, DateFormat('hh:mm a').format(alarm.dateTime));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlarmRingScreen(
        alarm: alarm,
        onDismiss: () {
          stopAlarmSound();
          _ringing.remove(alarm.id);
          Navigator.of(ctx).pop();
        },
        onSnooze: () {
          stopAlarmSound();
          _ringing.remove(alarm.id);
          _alarmService.updateAlarm(
            alarm.id,
            dateTime: DateTime.now().add(const Duration(minutes: 5)),
            isActive: true,
            hasFired: false,
          );
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: colorScheme.error),
            const SizedBox(width: 12),
            const Text('Logout?'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await _logout(context);
    }
  }

  late final screens = [
    DashboardScreen(
        toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    MultimediaScreen(
        toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    const TimePickerScreen(),
    const NotesScreen(),
    const SubjectListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final displayName = email.isNotEmpty ? email.split('@').first : 'Student';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Hub',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Hi, $displayName 👋',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Switch to Light' : 'Switch to Dark',
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                            fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(widget.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                title: Text(widget.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.toggleTheme();
                },
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle), label: 'Media'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.note), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Subjects'),
        ],
      ),
    );
  }
}

///////////////////////////////////////////////////////////
/// DASHBOARD
///////////////////////////////////////////////////////////

class DashboardScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  void nav(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Tasks', Icons.task_alt, TaskListScreen(), Colors.indigo],
      [
        'Multimedia',
        Icons.play_circle,
        MultimediaScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
        Colors.pink
      ],
      ['Image Editor', Icons.image, const ImageTransformScreen(), Colors.teal],
      ['Timer', Icons.timer, const TimePickerScreen(), Colors.orange],
      ['Notes', Icons.note, const NotesScreen(), Colors.green],
      ['Calculator', Icons.calculate, CalculatorScreen(), Colors.blue],
      ['Chatbot', Icons.smart_toy, const ChatbotScreen(), Colors.purple],
      ['Analytics', Icons.bar_chart, const AnalyticsScreen(), Colors.deepPurple],
    ];

    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (c, i) {
              final title = items[i][0] as String;
              final icon = items[i][1] as IconData;
              final screen = items[i][2] as Widget;
              final color = items[i][3] as Color;

              return GestureDetector(
                onTap: () => nav(context, screen),
                child: GlassCard(
                  color: color,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 34, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
