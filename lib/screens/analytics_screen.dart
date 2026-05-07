import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/study_session_model.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  late final Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _streakFuture = _analyticsService.calculateStudyStreak(lookbackDays: 30);
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  List<BarChartGroupData> _buildBarGroups(List<StudySessionModel> sessions) {
    final now = DateTime.now();
    final dayTotals = <String, double>{};
    final dayLabels = List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      final label = DateFormat.E().format(day);
      dayTotals[label] = 0.0;
      return label;
    });

    for (final session in sessions) {
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      final label = DateFormat.E().format(date);
      if (dayTotals.containsKey(label)) {
        dayTotals[label] = dayTotals[label]! + session.duration.inMinutes;
      }
    }

    return dayLabels.asMap().entries.map((entry) {
      final index = entry.key;
      final label = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dayTotals[label]!.toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(6),
            color: Colors.indigo.shade400,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.15) ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? Colors.blue, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Analytics'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insights from your study habits and tasks',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 18),

              // Summary cards
              Row(
                children: [
                  StreamBuilder<int>(
                    stream: _analyticsService.getTodayStudyTimeSeconds(),
                    builder: (context, snapshot) {
                      final studySeconds = snapshot.data ?? 0;
                      final label = studySeconds > 0
                          ? _formatDuration(studySeconds)
                          : 'No study time yet';
                      return _buildSummaryCard(
                        title: 'Today Study',
                        value: label,
                        icon: Icons.timer,
                        color: Colors.orange,
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _analyticsService.getTasksCompletedTodayCount(),
                    builder: (context, snapshot) {
                      final completed = snapshot.data ?? 0;
                      return _buildSummaryCard(
                        title: 'Tasks Today',
                        value: '$completed completed',
                        icon: Icons.task_alt,
                        color: Colors.green,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: _streakFuture,
                builder: (context, snapshot) {
                  final streak = snapshot.data ?? 0;
                  final label = streak > 0 ? '🔥 $streak-day streak' : 'Start a streak';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.whatshot, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Study Streak',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Bar chart
              const Text(
                'Last 7 days study time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: StreamBuilder<List<StudySessionModel>>(
                  stream: _analyticsService.getStudySessionsForLastDays(7),
                  builder: (context, snapshot) {
                    final sessions = snapshot.data ?? [];
                    final groups = _buildBarGroups(sessions);

                    if (sessions.isEmpty) {
                      return SizedBox(
                        height: 220,
                        child: Center(
                          child: Text(
                            'No study sessions in the last 7 days 📭',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 260,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: groups
                                  .map((group) => group.barRods.first.toY)
                                  .fold<double>(0, (a, b) => a > b ? a : b) +
                              5,
                          barGroups: groups,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 15,
                                getTitlesWidget: (value, meta) {
                                  final label = value.toInt();
                                  return Text(
                                    '$label m',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  final labels = groups
                                      .asMap()
                                      .map((i, g) => MapEntry(i, DateFormat.E().format(DateTime.now().subtract(Duration(days: 6 - i)))))
                                      .values
                                      .toList();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      labels[index],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Pie chart
              const Text(
                'Task completion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: StreamBuilder<int>(
                  stream: _analyticsService.getTotalCompletedTasksCount(),
                  builder: (context, completedSnapshot) {
                    return StreamBuilder<int>(
                      stream: _analyticsService.getPendingTasksCount(),
                      builder: (context, pendingSnapshot) {
                        final completed = completedSnapshot.data ?? 0;
                        final pending = pendingSnapshot.data ?? 0;
                        final total = completed + pending;

                        if (total == 0) {
                          return SizedBox(
                            height: 220,
                            child: Center(
                              child: Text(
                                'No tasks found yet 📭',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: completed.toDouble(),
                                      color: Colors.green.shade400,
                                      title: '${((completed / total) * 100).round()}%',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: pending.toDouble(),
                                      color: Colors.orange.shade400,
                                      title: '${((pending / total) * 100).round()}%',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLegendDot(Colors.green.shade400, 'Completed', completed),
                                _buildLegendDot(Colors.orange.shade400, 'Pending', pending),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Great job! Keep the streak going 🔥',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Analytics will update automatically as you log study sessions and complete tasks.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)'),
      ],
    );
  }
}
