import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';
import 'habit_repository.dart';

/// Aggregated achievement metrics derived from the current habits.
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  final habits = ref.watch(habitRepositoryProvider);
  return AchievementService.computeStats(habits);
});

/// The full catalogue of achievements with their unlocked/progress state
/// recomputed whenever the underlying habits change.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final stats = ref.watch(achievementStatsProvider);
  return AchievementService.evaluate(stats);
});
