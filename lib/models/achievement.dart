import 'package:flutter/material.dart';

/// Thematic grouping for achievements, used for section headers and theming.
enum AchievementCategory {
  milestones,
  streaks,
  consistency,
  collection,
  dedication,
}

extension AchievementCategoryX on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.streaks:
        return 'Streaks';
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.dedication:
        return 'Dedication';
    }
  }
}

/// A single achievement definition together with its evaluated runtime state.
///
/// Achievements are pure functions of the user's habit data, so [unlocked],
/// [progress] and [progressLabel] are recomputed whenever habits change rather
/// than persisted directly.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.target,
    required this.value,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;

  /// The value the user needs to reach to unlock the achievement.
  final int target;

  /// The user's current value for this achievement's metric.
  final int value;

  bool get unlocked => value >= target;

  /// Progress towards unlocking, clamped to the 0..1 range.
  double get progress =>
      target <= 0 ? 1 : (value / target).clamp(0.0, 1.0).toDouble();

  String get progressLabel => '${value.clamp(0, target)} / $target';

  Achievement copyWith({int? value}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      category: category,
      target: target,
      value: value ?? this.value,
    );
  }
}
