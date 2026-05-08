import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
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
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  List<BarChartGroupData> _buildBarGroups(List<StudySessionModel> sessions) {
    final now = DateTime.now();
    final dayTotals = <String, double>{};
    final dayLabels = List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
      final label = DateFormat.E().format(day);
      dayTotals[label] = 0.0;
      return label;
    });
    for (final s in sessions) {
      final label = DateFormat.E().format(DateTime(s.date.year, s.date.month, s.date.day));
      if (dayTotals.containsKey(label)) {
        dayTotals[label] = dayTotals[label]! + s.duration.inMinutes;
      }
    }
    return dayLabels.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: dayTotals[e.value]!,
            width: 18,
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [kPrimary, kMint],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _summaryCard({required String title, required String value,
      required IconData icon, required Color color, bool isDark = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2A2A3D))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? kDarkCard : Colors.white;
    final textSub = isDark ? Colors.white54 : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Insights from your study habits',
                style: TextStyle(fontSize: 14, color: textSub)),
            const SizedBox(height: 16),

            // ── Summary cards ────────────────────────────────────
            Row(children: [
              StreamBuilder<int>(
                stream: _analyticsService.getTodayStudyTimeSeconds(),
                builder: (_, snap) {
                  final s = snap.data ?? 0;
                  return _summaryCard(
                    title: 'Today Study',
                    value: s > 0 ? _formatDuration(s) : '—',
                    icon: Icons.timer_rounded,
                    color: kAmber,
                    isDark: isDark,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: _analyticsService.getTasksCompletedTodayCount(),
                builder: (_, snap) {
                  return _summaryCard(
                    title: 'Tasks Today',
                    value: '${snap.data ?? 0} done',
                    icon: Icons.task_alt_rounded,
                    color: kMint,
                    isDark: isDark,
                  );
                },
              ),
            ]),

            // ── Streak card ──────────────────────────────────────
            FutureBuilder<int>(
              future: _streakFuture,
              builder: (_, snap) {
                final streak = snap.data ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [kPrimary.withOpacity(0.25), kMint.withOpacity(0.15)]
                          : [kPrimaryLight.withOpacity(0.6), kMintLight.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.local_fire_department_rounded, color: kPrimary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Study Streak', style: TextStyle(fontSize: 13, color: textSub, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        streak > 0 ? '🔥 $streak-day streak!' : 'Start a streak today',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF2A2A3D)),
                      ),
                    ]),
                  ]),
                );
              },
            ),

            // ── Bar chart ────────────────────────────────────────
            Text('Study time — last 7 days',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2A2A3D))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : kPrimary.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: StreamBuilder<List<StudySessionModel>>(
                stream: _analyticsService.getStudySessionsForLastDays(7),
                builder: (_, snap) {
                  final sessions = snap.data ?? [];
                  final groups = _buildBarGroups(sessions);
                  if (sessions.isEmpty) {
                    return SizedBox(height: 200, child: Center(
                        child: Text('No study sessions yet 📭',
                            style: TextStyle(color: textSub))));
                  }
                  return SizedBox(
                    height: 240,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: groups.map((g) => g.barRods.first.toY).fold<double>(0, (a, b) => a > b ? a : b) + 5,
                      barGroups: groups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 36, interval: 15,
                          getTitlesWidget: (v, _) => Text('${v.toInt()}m',
                              style: TextStyle(fontSize: 10, color: textSub)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final labels = groups.asMap().map((i, _) => MapEntry(i,
                                DateFormat.E().format(DateTime.now().subtract(Duration(days: 6 - i))))).values.toList();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(labels[v.toInt()],
                                  style: TextStyle(fontSize: 12, color: textSub)));
                          },
                        )),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.12),
                              strokeWidth: 1)),
                      borderData: FlBorderData(show: false),
                    )),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Pie chart ────────────────────────────────────────
            Text('Task completion',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2A2A3D))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16), width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : kMint.withOpacity(0.15)),
                boxShadow: [BoxShadow(color: kMint.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: StreamBuilder<int>(
                stream: _analyticsService.getTotalCompletedTasksCount(),
                builder: (_, completedSnap) => StreamBuilder<int>(
                  stream: _analyticsService.getPendingTasksCount(),
                  builder: (_, pendingSnap) {
                    final completed = completedSnap.data ?? 0;
                    final pending = pendingSnap.data ?? 0;
                    final total = completed + pending;
                    if (total == 0) {
                      return SizedBox(height: 180, child: Center(
                          child: Text('No tasks yet 📭', style: TextStyle(color: textSub))));
                    }
                    return Column(children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: completed.toDouble(), color: kMint,
                              title: '${((completed / total) * 100).round()}%',
                              radius: 64,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            PieChartSectionData(
                              value: pending.toDouble(), color: kAmber,
                              title: '${((pending / total) * 100).round()}%',
                              radius: 54,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                          sectionsSpace: 4,
                          centerSpaceRadius: 36,
                        )),
                      ),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        _legendDot(kMint, 'Completed', completed, isDark),
                        _legendDot(kAmber, 'Pending', pending, isDark),
                      ]),
                    ]);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Motivation banner ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAmber.withOpacity(isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kAmber.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Text('🌟', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Keep the streak going!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2A2A3D))),
                  const SizedBox(height: 4),
                  Text('Analytics update as you log sessions and complete tasks.',
                      style: TextStyle(fontSize: 12, color: textSub)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label, int count, bool isDark) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('$label ($count)',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
    ]);
  }
}
