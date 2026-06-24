import { ArrowLeft, TrendingUp, Target, Award, Calendar } from 'lucide-react';
import { Habit } from '../App';
import { getIconComponent } from './IconPicker';

interface AnalyticsProps {
  habits: Habit[];
  onBack: () => void;
}

export function Analytics({ habits, onBack }: AnalyticsProps) {
  const today = new Date().toISOString().split('T')[0];

  // Calculate overall stats
  const calculateStats = () => {
    let totalCompleted = 0;
    let totalDays = 0;
    let longestStreak = 0;
    let currentOverallStreak = 0;

    habits.forEach(habit => {
      const dates = Object.keys(habit.history).sort();
      let habitStreak = 0;
      
      dates.forEach(date => {
        totalDays++;
        if (habit.history[date].status === 'completed') {
          totalCompleted++;
          habitStreak++;
        } else if (new Date(date) < new Date(today)) {
          if (habitStreak > longestStreak) {
            longestStreak = habitStreak;
          }
          habitStreak = 0;
        }
      });

      if (habitStreak > longestStreak) {
        longestStreak = habitStreak;
      }
    });

    // Calculate today's completion rate
    const todayCompleted = habits.filter(h => h.history[today]?.status === 'completed').length;
    const todayRate = habits.length > 0 ? Math.round((todayCompleted / habits.length) * 100) : 0;

    // Calculate this week's completion rate
    const weekDates = Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - i);
      return d.toISOString().split('T')[0];
    });

    let weekCompleted = 0;
    let weekTotal = 0;
    habits.forEach(habit => {
      weekDates.forEach(date => {
        weekTotal++;
        if (habit.history[date]?.status === 'completed') {
          weekCompleted++;
        }
      });
    });

    const weekRate = weekTotal > 0 ? Math.round((weekCompleted / weekTotal) * 100) : 0;

    return {
      completionRate: totalDays > 0 ? Math.round((totalCompleted / totalDays) * 100) : 0,
      longestStreak,
      todayRate,
      weekRate,
      totalCompleted
    };
  };

  const stats = calculateStats();

  // Get habit-specific stats
  const getHabitStats = (habit: Habit) => {
    const dates = Object.keys(habit.history).sort();
    let completed = 0;
    let skipped = 0;
    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 0;

    dates.forEach((date, index) => {
      const status = habit.history[date].status;
      if (status === 'completed') {
        completed++;
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (status === 'skipped') {
        skipped++;
        tempStreak = 0;
      } else {
        if (new Date(date) < new Date(today)) {
          tempStreak = 0;
        }
      }
    });

    // Calculate current streak
    const sortedDates = dates.sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
    for (const date of sortedDates) {
      if (habit.history[date].status === 'completed') {
        currentStreak++;
      } else if (new Date(date) < new Date(today)) {
        break;
      }
    }

    const total = dates.length;
    const rate = total > 0 ? Math.round((completed / total) * 100) : 0;

    return { completed, skipped, currentStreak, longestStreak, rate };
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={onBack}
          className="p-2 hover:bg-white/5 rounded-xl transition-colors"
          aria-label="Back"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <h2>Analytics & Insights</h2>
      </div>

      {/* Overall Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-[#1a2332] rounded-2xl p-5 border border-white/5">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-blue-500/20 rounded-xl">
              <TrendingUp className="w-4 h-4 text-blue-400" />
            </div>
            <span className="text-sm text-[#9aa3b2]">Overall</span>
          </div>
          <p className="text-2xl mb-1">{stats.completionRate}%</p>
          <p className="text-xs text-[#9aa3b2]">Completion rate</p>
        </div>

        <div className="bg-[#1a2332] rounded-2xl p-5 border border-white/5">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-orange-500/20 rounded-xl">
              <Award className="w-4 h-4 text-orange-400" />
            </div>
            <span className="text-sm text-[#9aa3b2]">Best</span>
          </div>
          <p className="text-2xl mb-1">{stats.longestStreak}</p>
          <p className="text-xs text-[#9aa3b2]">Longest streak</p>
        </div>

        <div className="bg-[#1a2332] rounded-2xl p-5 border border-white/5">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-green-500/20 rounded-xl">
              <Target className="w-4 h-4 text-green-400" />
            </div>
            <span className="text-sm text-[#9aa3b2]">Today</span>
          </div>
          <p className="text-2xl mb-1">{stats.todayRate}%</p>
          <p className="text-xs text-[#9aa3b2]">Completed</p>
        </div>

        <div className="bg-[#1a2332] rounded-2xl p-5 border border-white/5">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-purple-500/20 rounded-xl">
              <Calendar className="w-4 h-4 text-purple-400" />
            </div>
            <span className="text-sm text-[#9aa3b2]">This Week</span>
          </div>
          <p className="text-2xl mb-1">{stats.weekRate}%</p>
          <p className="text-xs text-[#9aa3b2]">Completed</p>
        </div>
      </div>

      {/* Per-Habit Stats */}
      <div>
        <h3 className="text-lg mb-4">Habit Breakdown</h3>
        <div className="space-y-3">
          {habits.map(habit => {
            const habitStats = getHabitStats(habit);
            const Icon = getIconComponent(habit.iconId);

            return (
              <div
                key={habit.id}
                className="bg-[#1a2332] rounded-2xl p-5 border border-white/5"
              >
                <div className="flex items-start gap-4">
                  <div
                    className="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center"
                    style={{ backgroundColor: `${habit.color}20` }}
                  >
                    <Icon className="w-6 h-6" style={{ color: habit.color }} />
                  </div>

                  <div className="flex-1 min-w-0">
                    <h4 className="mb-1">{habit.title}</h4>
                    
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mt-3">
                      <div>
                        <p className="text-xs text-[#9aa3b2] mb-1">Current Streak</p>
                        <p className="flex items-center gap-1">
                          {habitStats.currentStreak > 0 && <span>🔥</span>}
                          <span>{habitStats.currentStreak} days</span>
                        </p>
                      </div>

                      <div>
                        <p className="text-xs text-[#9aa3b2] mb-1">Best Streak</p>
                        <p>{habitStats.longestStreak} days</p>
                      </div>

                      <div>
                        <p className="text-xs text-[#9aa3b2] mb-1">Completed</p>
                        <p>{habitStats.completed} times</p>
                      </div>

                      <div>
                        <p className="text-xs text-[#9aa3b2] mb-1">Success Rate</p>
                        <p>{habitStats.rate}%</p>
                      </div>
                    </div>

                    {/* Progress Bar */}
                    <div className="mt-3">
                      <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all duration-500"
                          style={{
                            width: `${habitStats.rate}%`,
                            backgroundColor: habit.color
                          }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}

          {habits.length === 0 && (
            <div className="text-center py-12">
              <p className="text-[#9aa3b2]">No habits to analyze yet</p>
            </div>
          )}
        </div>
      </div>

      {/* Insights */}
      <div className="bg-[#1a2332] rounded-2xl p-6 border border-white/5">
        <h3 className="text-lg mb-4">💡 Insights</h3>
        <div className="space-y-3 text-sm">
          {stats.weekRate >= 80 && (
            <p className="text-green-400">
              ✓ Excellent! You're maintaining {stats.weekRate}% completion this week
            </p>
          )}
          {stats.weekRate < 50 && stats.weekRate > 0 && (
            <p className="text-orange-400">
              ⚠ Your completion rate dropped to {stats.weekRate}% this week. Try starting with smaller goals!
            </p>
          )}
          {stats.longestStreak >= 7 && (
            <p className="text-purple-400">
              🎉 Amazing! Your longest streak is {stats.longestStreak} days
            </p>
          )}
          {habits.length >= 5 && (
            <p className="text-blue-400">
              💪 You're tracking {habits.length} habits. Consider focusing on your top priorities for better results.
            </p>
          )}
          {stats.totalCompleted === 0 && (
            <p className="text-[#9aa3b2]">
              Start completing your habits to see personalized insights here
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
