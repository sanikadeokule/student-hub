import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Time & Productivity',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withValues(alpha:0.3),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: Icon(Icons.timer)),
                    Tab(icon: Icon(Icons.alarm)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    PomodoroTab(),
                    AlarmTab(),
                  ],
                ),
              ),
            ],
          ),
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
    if (elapsed >= 10) {
      await _analyticsService.logStudySession(Duration(seconds: elapsed));
    }
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
    setState(() {
      isRunning = false;
      isBreak = false;
      secondsLeft = workMins * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mins = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (secondsLeft % 60).toString().padLeft(2, '0');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBreak ? 'Break Time 😌' : 'Focus Time 🔥',
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Text(
                '$mins:$secs',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            onPressed: toggle,
            child: Text(isRunning ? 'Pause' : 'Start'),
          ),
          TextButton(
            onPressed: reset,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
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
    _sub = _service.getAlarms().listen((alarms) {
      if (mounted) setState(() => _alarms = alarms);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'New Alarm',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Alarm name (e.g. "Physics exam")',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.label_outline,
                        color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        icon: Icons.calendar_today,
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
                        icon: Icons.access_time,
                        label: pickedTime == null
                            ? 'Pick Time'
                            : pickedTime!.format(ctx),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null) setSheet(() => pickedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (pickedDate == null || pickedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please pick both date and time')),
                      );
                      return;
                    }
                    final dt = DateTime(
                      pickedDate!.year,
                      pickedDate!.month,
                      pickedDate!.day,
                      pickedTime!.hour,
                      pickedTime!.minute,
                    );
                    if (dt.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Alarm time must be in the future')),
                      );
                      return;
                    }
                    initAudioContext();
                    _service.addAlarm(
                      name: nameCtrl.text.trim().isEmpty
                          ? 'Alarm'
                          : nameCtrl.text.trim(),
                      dateTime: dt,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child:
                      const Text('Set Alarm', style: TextStyle(fontSize: 16)),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _alarms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('No alarms set',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Tap + to add one',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              itemBuilder: (_, i) {
                final alarm = _alarms[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: alarm.isActive ? 0.15 : 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: alarm.isActive ? 0.3 : 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alarm.name,
                              style: TextStyle(
                                color: alarm.isActive
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy · hh:mm a')
                                  .format(alarm.dateTime),
                              style: TextStyle(
                                color: alarm.isActive
                                    ? Colors.white70
                                    : Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alarm.hasFired)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Text('Rang',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        )
                      else
                        Switch(
                          value: alarm.isActive,
                          onChanged: (val) =>
                              _service.updateAlarm(alarm.id, isActive: val),
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF5C6BC0),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white54),
                        onPressed: () => _service.deleteAlarm(alarm.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Sheet helper button ────────────────────────────────────────

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis),
      onPressed: onTap,
    );
  }
}

// ─── Alarm Ring Screen ─────────────────────────────────────────

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  const AlarmRingScreen({
    super.key,
    required this.alarm,
    required this.onDismiss,
    required this.onSnooze,
  });

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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7B0000),
              Color(0xFFD32F2F),
              Color(0xFFEF5350),
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
                child: const Icon(Icons.alarm, size: 96, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text(
                'A  L  A  R  M',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                widget.alarm.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('hh:mm a').format(widget.alarm.dateTime),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.snooze),
                    label: const Text('Snooze 5 min'),
                    onPressed: widget.onSnooze,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.alarm_off),
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
