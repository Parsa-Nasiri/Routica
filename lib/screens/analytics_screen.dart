import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../providers/habit_manager.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    required this.habits,
    this.onBack,
  });

  final List<Habit> habits;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: onBack,
                      ),
                    const SizedBox(width: 4),
                    const Text(
                      'Analytics & Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOverallCards(stats),
                const SizedBox(height: 24),
                _buildHabitBreakdown(),
                const SizedBox(height: 24),
                _buildInsights(stats),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, num> _calculateStats() {
    final today = DateTime.now().toIso8601String().split('T').first;

    var totalCompleted = 0;
    var totalDays = 0;
    var longestStreak = 0;

    for (final habit in habits) {
      final dates = habit.history.keys.toList()..sort();
      var habitStreak = 0;

      for (final date in dates) {
        totalDays++;
        final status = habit.history[date]?.status;
        if (status == HabitDayStatus.completed) {
          totalCompleted++;
          habitStreak++;
        } else if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
          if (habitStreak > longestStreak) {
            longestStreak = habitStreak;
          }
          habitStreak = 0;
        }
      }

      if (habitStreak > longestStreak) {
        longestStreak = habitStreak;
      }
    }

    final todayCompleted =
        habits.where((h) => h.history[today]?.status == HabitDayStatus.completed).length;
    final todayRate = habits.isNotEmpty
        ? ((todayCompleted / habits.length) * 100).round()
        : 0;

    final weekDates = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: i));
      return d.toIso8601String().split('T').first;
    });

    var weekCompleted = 0;
    var weekTotal = 0;
    for (final habit in habits) {
      for (final date in weekDates) {
        weekTotal++;
        if (habit.history[date]?.status == HabitDayStatus.completed) {
          weekCompleted++;
        }
      }
    }

    final weekRate = weekTotal > 0 ? ((weekCompleted / weekTotal) * 100).round() : 0;

    final completionRate =
        totalDays > 0 ? ((totalCompleted / totalDays) * 100).round() : 0;

    return {
      'completionRate': completionRate,
      'longestStreak': longestStreak,
      'todayRate': todayRate,
      'weekRate': weekRate,
      'totalCompleted': totalCompleted,
    };
  }

  Widget _buildOverallCards(Map<String, num> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          title: 'Overall',
          value: '${stats['completionRate']}%',
          subtitle: 'Completion rate',
          icon: Icons.trending_up,
          iconBgColor: const Color(0x333B82F6), // blue-500/20
          iconColor: const Color(0xFF60A5FA), // blue-400
        ),
        _statCard(
          title: 'Best',
          value: '${stats['longestStreak']}',
          subtitle: 'Longest streak',
          icon: Icons.emoji_events,
          iconBgColor: const Color(0x33F59E0B), // orange-500/20
          iconColor: const Color(0xFFFB923C), // orange-400
        ),
        _statCard(
          title: 'Today',
          value: '${stats['todayRate']}%',
          subtitle: 'Completed',
          icon: Icons.gps_fixed,
          iconBgColor: const Color(0x3310B981), // green-500/20
          iconColor: const Color(0xFF4ADE80), // green-400
        ),
        _statCard(
          title: 'This Week',
          value: '${stats['weekRate']}%',
          subtitle: 'Completed',
          icon: Icons.calendar_today,
          iconBgColor: const Color(0x33A855F7), // purple-500/20
          iconColor: const Color(0xFFC084FC), // purple-400
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitBreakdown() {
    if (habits.isEmpty) {
      return const Center(
        child: Text(
          'No habits to analyze yet',
          style: TextStyle(color: Color(0xFF9AA3B2)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habit Breakdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...habits.map(_buildHabitStatsCard),
      ],
    );
  }

  Widget _buildHabitStatsCard(Habit habit) {
    final stats = _getHabitStats(habit);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Current Streak', '${stats['currentStreak']} days'),
              _miniStat('Best Streak', '${stats['longestStreak']} days'),
              _miniStat('Completed', '${stats['completed']} times'),
              _miniStat('Success', '${stats['rate']}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (stats['rate'] as num) / 100.0,
              minHeight: 6,
              backgroundColor: const Color(0x14FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(habit.color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Map<String, num> _getHabitStats(Habit habit) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final dates = habit.history.keys.toList()..sort();

    var completed = 0;
    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 0;

    for (final date in dates) {
      final status = habit.history[date]?.status;
      if (status == HabitDayStatus.completed) {
        completed++;
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
          tempStreak = 0;
        }
      }
    }

    final sortedDates = dates
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    currentStreak = 0;
    for (final date in sortedDates) {
      final status = habit.history[date]?.status;
      if (status == HabitDayStatus.completed) {
        currentStreak++;
      } else if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
        break;
      }
    }

    final total = dates.length;
    final rate = total > 0 ? ((completed / total) * 100).round() : 0;

    return {
      'completed': completed,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'rate': rate,
    };
  }

  Widget _buildInsights(Map<String, num> stats) {
    final weekRate = stats['weekRate'] as num;
    final longestStreak = stats['longestStreak'] as num;
    final totalCompleted = stats['totalCompleted'] as num;
    final completionRate = stats['completionRate'] as num;
    
    // Generate smart suggestions
    final suggestions = _generateAISuggestions(weekRate, longestStreak, totalCompleted, completionRate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x332B2EEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF2B2EEE), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Suggestions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['icon'] as String,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion['text'] as String,
                    style: TextStyle(
                      color: suggestion['color'] as Color,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (suggestions.isEmpty)
            const Text(
              'Complete more habits to unlock personalized AI insights',
              style: TextStyle(color: Color(0xFF9AA3B2), fontSize: 13),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateAISuggestions(
    num weekRate,
    num longestStreak,
    num totalCompleted,
    num completionRate,
  ) {
    final suggestions = <Map<String, dynamic>>[];

    // No data yet
    if (totalCompleted == 0) {
      return [];
    }

    // 1. PERFORMANCE ANALYSIS (Priority: High)
    if (weekRate >= 90) {
      suggestions.add({
        'icon': '🔥',
        'text': 'Outstanding! You\'re crushing it with ${weekRate.toInt()}% completion this week. Keep this momentum going!',
        'color': const Color(0xFF4ADE80),
      });
    } else if (weekRate >= 70) {
      suggestions.add({
        'icon': '✅',
        'text': 'Great work! ${weekRate.toInt()}% completion rate. You\'re on the right track to building lasting habits.',
        'color': const Color(0xFF4ADE80),
      });
    } else if (weekRate >= 50) {
      suggestions.add({
        'icon': '💡',
        'text': 'You\'re at ${weekRate.toInt()}%. Try habit stacking: link new habits to existing routines for better consistency.',
        'color': const Color(0xFF60A5FA),
      });
    } else if (weekRate > 0) {
      suggestions.add({
        'icon': '⚡',
        'text': '${weekRate.toInt()}% completion detected. Start with just 1-2 habits and build from there. Small wins create momentum!',
        'color': const Color(0xFFF97316),
      });
    }

    // 2. STREAK RECOGNITION
    if (longestStreak >= 21) {
      suggestions.add({
        'icon': '🏆',
        'text': 'Incredible ${longestStreak.toInt()}-day streak! Research shows it takes 21+ days to form a habit. You\'ve done it!',
        'color': const Color(0xFFA855F7),
      });
    } else if (longestStreak >= 7) {
      suggestions.add({
        'icon': '🎯',
        'text': '${longestStreak.toInt()} days strong! You\'re halfway to the 21-day habit formation threshold. Don\'t break the chain!',
        'color': const Color(0xFFA855F7),
      });
    } else if (longestStreak >= 3) {
      suggestions.add({
        'icon': '🌱',
        'text': '${longestStreak.toInt()}-day streak started! The first week is the hardest. Keep pushing!',
        'color': const Color(0xFF60A5FA),
      });
    }

    // 3. HABIT LOAD ANALYSIS
    if (habits.length >= 7) {
      suggestions.add({
        'icon': '⚠️',
        'text': 'Tracking ${habits.length} habits may be overwhelming. Focus on 3-5 core habits for 80% better results.',
        'color': const Color(0xFFF97316),
      });
    } else if (habits.length >= 5) {
      suggestions.add({
        'icon': '📊',
        'text': '${habits.length} active habits. Prioritize the ones that align with your top 3 goals this month.',
        'color': const Color(0xFF60A5FA),
      });
    }

    // 4. COMPLETION MILESTONE
    if (totalCompleted >= 100) {
      suggestions.add({
        'icon': '💯',
        'text': '${totalCompleted.toInt()} completions! You\'ve built serious discipline. Consider adding a challenge habit.',
        'color': const Color(0xFF4ADE80),
      });
    } else if (totalCompleted >= 50) {
      suggestions.add({
        'icon': '📈',
        'text': '${totalCompleted.toInt()} completions achieved. You\'re proving consistency. Halfway to 100!',
        'color': const Color(0xFF60A5FA),
      });
    } else if (totalCompleted >= 10) {
      suggestions.add({
        'icon': '🎊',
        'text': 'First ${totalCompleted.toInt()} completions recorded! Every journey starts with small steps.',
        'color': const Color(0xFF60A5FA),
      });
    }

    // 5. OVERALL RATE INSIGHT
    if (completionRate >= 80 && weekRate < 50) {
      suggestions.add({
        'icon': '📉',
        'text': 'Your overall rate (${completionRate.toInt()}%) is strong, but this week dipped to ${weekRate.toInt()}%. Refocus on your why.',
        'color': const Color(0xFFF97316),
      });
    }

    // 6. GOAL PROGRESS ANALYSIS
    var behindGoals = 0;
    var achievedGoals = 0;
    for (final habit in habits) {
      final progress = HabitManager.calculateGoalProgress(habit);
      if (progress.achieved) {
        achievedGoals++;
      } else if (progress.percentage < 50 && progress.goal > 0) {
        behindGoals++;
      }
    }

    if (behindGoals > 0 && habits.isNotEmpty) {
      suggestions.add({
        'icon': '⏰',
        'text': '$behindGoals habit${behindGoals > 1 ? "s are" : " is"} behind schedule. Focus on completing them before the period ends!',
        'color': const Color(0xFFF97316),
      });
    } else if (achievedGoals > 0 && achievedGoals == habits.length) {
      suggestions.add({
        'icon': '🎉',
        'text': 'Amazing! You\'ve hit ALL your goals this period. Consider increasing your targets!',
        'color': const Color(0xFF4ADE80),
      });
    } else if (achievedGoals >= habits.length / 2 && habits.isNotEmpty) {
      suggestions.add({
        'icon': '✨',
        'text': '$achievedGoals/${habits.length} goals achieved! Keep the momentum going.',
        'color': const Color(0xFF4ADE80),
      });
    }

    // 7. MOTIVATIONAL BOOST (if low activity)
    if (suggestions.length < 2 && totalCompleted > 0) {
      suggestions.add({
        'icon': '💪',
        'text': 'Every habit completion is a vote for the person you want to become. Keep voting!',
        'color': const Color(0xFF60A5FA),
      });
    }

    return suggestions.take(3).toList(); // Max 3 suggestions to avoid clutter
  }
}
