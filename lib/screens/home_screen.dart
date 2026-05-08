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
import 'alarm_audio_stub.dart'
    if (dart.library.js_interop) 'alarm_audio_web.dart';

import '../config/app_theme.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  const HomeScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];
  StreamSubscription<List<AlarmModel>>? _alarmSub;
  Timer? _alarmTimer;
  final Set<String> _ringing = {};

  @override
  void initState() {
    super.initState();
    _alarmSub = _alarmService.getAlarms().listen((list) => _alarms = list);
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAlarms());
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
      if (alarm.isActive && !alarm.hasFired && now.isAfter(alarm.dateTime) && !_ringing.contains(alarm.id)) {
        _ringing.add(alarm.id);
        _alarmService.updateAlarm(alarm.id, isActive: false, hasFired: true);
        _fireAlarm(alarm);
        break;
      }
    }
  }

  void _fireAlarm(AlarmModel alarm) {
    playAlarmSound();
    showBrowserNotification(alarm.name, DateFormat('hh:mm a').format(alarm.dateTime));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlarmRingScreen(
        alarm: alarm,
        onDismiss: () { stopAlarmSound(); _ringing.remove(alarm.id); Navigator.of(ctx).pop(); },
        onSnooze: () {
          stopAlarmSound();
          _ringing.remove(alarm.id);
          _alarmService.updateAlarm(alarm.id,
              dateTime: DateTime.now().add(const Duration(minutes: 5)),
              isActive: true, hasFired: false);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)),
      (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kCoral.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout_rounded, color: kCoral, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Logout?'),
        ]),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCoral, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await _logout(context);
  }

  late final screens = [
    DashboardScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    MultimediaScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    const TimePickerScreen(),
    const NotesScreen(),
    const SubjectListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final displayName = email.isNotEmpty ? email.split('@').first : 'Student';
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Student Hub'),
          Text('Hi, $displayName 👋',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal,
                  color: isDark ? Colors.white60 : const Color(0xFF2A2A3D).withOpacity(0.55))),
        ]),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: widget.toggleTheme,
          ),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => _confirmLogout(context)),
        ],
      ),
      drawer: _buildDrawer(context, displayName, email, isDark),
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_rounded), label: 'Media'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer_rounded), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), selectedIcon: Icon(Icons.sticky_note_2_rounded), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Subjects'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String displayName, String email, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? kDarkCard : kLightCard,
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            gradient: isDark ? kPrimaryGradientDark : kPrimaryGradient,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.22),
              child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            Text(email, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kPrimaryLight.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
            child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: kPrimary, size: 20),
          ),
          title: Text(isDark ? 'Light Mode' : 'Dark Mode', style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () { Navigator.of(context).pop(); widget.toggleTheme(); },
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kCoral.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout_rounded, color: kCoral, size: 20),
          ),
          title: const Text('Logout', style: TextStyle(color: kCoral, fontWeight: FontWeight.w500)),
          onTap: () { Navigator.of(context).pop(); _confirmLogout(context); },
        ),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DASHBOARD
// ─────────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const DashboardScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  void _nav(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Tasks',        Icons.task_alt_rounded,       TaskListScreen(),                                                   kPrimary],
      ['Media',        Icons.play_circle_rounded,    MultimediaScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode), kMint  ],
      ['Image Editor', Icons.auto_fix_high_rounded,  const ImageTransformScreen(),                                       kAmber ],
      ['Timer',        Icons.timer_rounded,          const TimePickerScreen(),                                           kCoral ],
      ['Notes',        Icons.sticky_note_2_rounded,  const NotesScreen(),                                                kPrimary],
      ['Calculator',   Icons.calculate_rounded,      const CalculatorScreen(),                                           kMint  ],
      ['AI Chatbot',   Icons.smart_toy_rounded,      const ChatbotScreen(),                                              kAmber ],
      ['Analytics',    Icons.bar_chart_rounded,      const AnalyticsScreen(),                                            kCoral ],
    ];

    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14,
            ),
            itemBuilder: (ctx, i) {
              final title  = items[i][0] as String;
              final icon   = items[i][1] as IconData;
              final screen = items[i][2] as Widget;
              final color  = items[i][3] as Color;
              return GestureDetector(
                onTap: () => _nav(ctx, screen),
                child: GlassCard(
                  color: color,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
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
