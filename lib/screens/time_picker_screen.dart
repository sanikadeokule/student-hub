import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/analytics_service.dart';
import 'alarm_audio_stub.dart' if (dart.library.js_interop) 'alarm_audio_web.dart';

// ─── Root Screen ───────────────────────────────────────────────

class TimePickerScreen extends StatefulWidget {
  const TimePickerScreen({super.key});

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kAmber.withOpacity(isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.timer_rounded, color: kAmber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Time & Productivity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ── Tab bar ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? kDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : kPrimary.withOpacity(0.12),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kPrimary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[500],
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(icon: Icon(Icons.timer_rounded), text: 'Pomodoro'),
                  Tab(icon: Icon(Icons.alarm_rounded), text: 'Alarm'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [PomodoroTab(), AlarmTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pomodoro ──────────────────────────────────────────────────

class PomodoroTab extends StatefulWidget {
  const PomodoroTab({super.key});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<PomodoroTab>
    with SingleTickerProviderStateMixin {
  static const int workMins = 25;
  static const int breakMins = 5;
  final AnalyticsService _analyticsService = AnalyticsService();

  int secondsLeft = workMins * 60;
  bool isRunning = false;
  bool isBreak = false;
  Timer? timer;

  double get progress =>
      secondsLeft / (isBreak ? breakMins * 60 : workMins * 60);

  Future<void> _logStudySegment() async {
    if (isBreak) return;
    final elapsed = workMins * 60 - secondsLeft;
    if (elapsed >= 10) await _analyticsService.logStudySession(Duration(seconds: elapsed));
  }

  void toggle() {
    if (isRunning) {
      timer?.cancel();
      _logStudySegment();
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (secondsLeft == 0) {
          timer?.cancel();
          await _logStudySegment();
          setState(() {
            isBreak = !isBreak;
            secondsLeft = (isBreak ? breakMins : workMins) * 60;
            isRunning = false;
          });
        } else {
          setState(() => secondsLeft--);
        }
      });
    }
    setState(() => isRunning = !isRunning);
  }

  void reset() {
    timer?.cancel();
    setState(() { isRunning = false; isBreak = false; secondsLeft = workMins * 60; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mins = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (secondsLeft % 60).toString().padLeft(2, '0');
    final accent = isBreak ? kMint : kAmber;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Text(
              isBreak ? '☕  Break Time' : '🔥  Focus Time',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),

          // Circular timer
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : accent.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$mins:$secs',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2A2A3D),
                    ),
                  ),
                  Text(
                    isBreak ? 'Break' : 'Focus',
                    style: TextStyle(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.grey[600],
                  side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset'),
                onPressed: reset,
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                label: Text(isRunning ? 'Pause' : 'Start',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: toggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alarm Tab ─────────────────────────────────────────────────

class AlarmTab extends StatefulWidget {
  const AlarmTab({super.key});

  @override
  State<AlarmTab> createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab> {
  final AlarmService _service = AlarmService();
  List<AlarmModel> _alarms = [];
  StreamSubscription<List<AlarmModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _service.getAlarms().listen((a) { if (mounted) setState(() => _alarms = a); });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? kDarkCard
                  : kLightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kCoral.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_add_rounded, color: kCoral, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('New Alarm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Alarm name (e.g. "Physics exam")',
                    prefixIcon: Icon(Icons.label_outline_rounded, color: kPrimary),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.calendar_today_rounded,
                      label: pickedDate == null
                          ? 'Pick Date'
                          : DateFormat('dd MMM yyyy').format(pickedDate!),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setSheet(() => pickedDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.access_time_rounded,
                      label: pickedTime == null ? 'Pick Time' : pickedTime!.format(ctx),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx, initialTime: TimeOfDay.now());
                        if (t != null) setSheet(() => pickedTime = t);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (pickedDate == null || pickedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please pick both date and time')));
                      return;
                    }
                    final dt = DateTime(pickedDate!.year, pickedDate!.month,
                        pickedDate!.day, pickedTime!.hour, pickedTime!.minute);
                    if (dt.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alarm time must be in the future')));
                      return;
                    }
                    initAudioContext();
                    _service.addAlarm(
                      name: nameCtrl.text.trim().isEmpty ? 'Alarm' : nameCtrl.text.trim(),
                      dateTime: dt,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Set Alarm', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _alarms.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCoral.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_off_rounded, size: 52, color: kCoral),
                ),
                const SizedBox(height: 16),
                Text('No alarms set',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[500],
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Tap + to add one',
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 13)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              itemBuilder: (_, i) {
                final alarm = _alarms[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? kDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: alarm.isActive
                          ? kCoral.withOpacity(0.35)
                          : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kCoral.withOpacity(alarm.isActive ? 0.08 : 0.03),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kCoral.withOpacity(alarm.isActive ? 0.15 : 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.alarm_rounded,
                          color: alarm.isActive ? kCoral : Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alarm.name,
                            style: TextStyle(
                                color: alarm.isActive
                                    ? (isDark ? Colors.white : const Color(0xFF2A2A3D))
                                    : (isDark ? Colors.white38 : Colors.grey[400]),
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy · hh:mm a').format(alarm.dateTime),
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    )),
                    if (alarm.hasFired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Rang',
                            style: TextStyle(color: kMint, fontSize: 11, fontWeight: FontWeight.w600)),
                      )
                    else
                      Switch(
                        value: alarm.isActive,
                        onChanged: (val) => _service.updateAlarm(alarm.id, isActive: val),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: isDark ? Colors.white24 : Colors.grey[400]),
                      onPressed: () => _service.deleteAlarm(alarm.id),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Sheet helper button ────────────────────────────────────────

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: BorderSide(color: kPrimary.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? kDarkSurface : kLightSurface,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      onPressed: onTap,
    );
  }
}

// ─── Alarm Ring Screen ─────────────────────────────────────────

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  const AlarmRingScreen({super.key, required this.alarm, required this.onDismiss, required this.onSnooze});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kCoral.withOpacity(0.9),
              kPrimary.withOpacity(0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_rounded, size: 72, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              const Text('A  L  A  R  M',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13,
                      letterSpacing: 8, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Text(widget.alarm.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(DateFormat('hh:mm a').format(widget.alarm.dateTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 20)),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.snooze_rounded),
                    label: const Text('Snooze 5 min'),
                    onPressed: widget.onSnooze,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kCoral,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.alarm_off_rounded),
                    label: const Text('Dismiss'),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
