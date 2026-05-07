import 'package:flutter/material.dart';
import 'dart:async';

import '../services/analytics_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

              // 🌟 HEADER
              const Text(
                "Time & Productivity",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // TAB BAR (GLASS STYLE)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.3),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(icon: Icon(Icons.timer)),
                    Tab(icon: Icon(Icons.access_time)),
                    Tab(icon: Icon(Icons.hourglass_bottom)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    PomodoroTab(),
                    DateTimePickerTab(),
                    CountdownTab(),
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

//////////////////////////////////////////////////////
// ⏱ POMODORO (ANIMATED)
//////////////////////////////////////////////////////

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
            isBreak ? "Break Time 😌" : "Focus Time 🔥",
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),

          const SizedBox(height: 20),

          // 🔵 CIRCULAR TIMER
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
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Text(
                "$mins:$secs",
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // BUTTONS
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            onPressed: toggle,
            child: Text(isRunning ? "Pause" : "Start"),
          ),

          TextButton(
            onPressed: reset,
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////
// 📅 DATE PICKER
//////////////////////////////////////////////////////

class DateTimePickerTab extends StatefulWidget {
  const DateTimePickerTab({super.key});

  @override
  State<DateTimePickerTab> createState() => _DateTimePickerTabState();
}

class _DateTimePickerTabState extends State<DateTimePickerTab> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => selectedTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: pickDate, child: const Text("Pick Date")),
          ElevatedButton(onPressed: pickTime, child: const Text("Pick Time")),
          const SizedBox(height: 20),
          Text(
            selectedDate == null
                ? "No date selected"
                : selectedDate.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            selectedTime == null
                ? "No time selected"
                : selectedTime!.format(context),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////
// ⏳ COUNTDOWN
//////////////////////////////////////////////////////

class CountdownTab extends StatefulWidget {
  const CountdownTab({super.key});

  @override
  State<CountdownTab> createState() => _CountdownTabState();
}

class _CountdownTabState extends State<CountdownTab> {
  DateTime? examDate;

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => examDate = d);
  }

  @override
  Widget build(BuildContext context) {
    int? daysLeft =
        examDate != null ? examDate!.difference(DateTime.now()).inDays : null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: pickDate, child: const Text("Select Date")),
          const SizedBox(height: 20),
          if (daysLeft != null)
            Text(
              "$daysLeft days remaining",
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
        ],
      ),
    );
  }
}