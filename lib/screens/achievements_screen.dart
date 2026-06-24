import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../theme/routica_theme.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    final byCategory = <AchievementCategory, List<Achievement>>{};
    for (final achievement in achievements) {
      byCategory.putIfAbsent(achievement.category, () => []).add(achievement);
    }

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
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(unlockedCount, achievements.length),
                const SizedBox(height: 24),
                for (final category in AchievementCategory.values)
                  if (byCategory[category] != null)
                    _buildCategory(category, byCategory[category]!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2332), Color(0xFF18243A)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x33FBBF24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFBBF24),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked of $total unlocked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked == total
                      ? 'Legendary! You collected them all.'
                      : 'Keep building habits to unlock more.',
                  style: const TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0x14FFFFFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    AchievementCategory category,
    List<Achievement> achievements,
  ) {
    final unlocked = achievements.where((a) => a.unlocked).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Row(
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$unlocked/${achievements.length}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
                children: achievements
                    .map((a) => _AchievementCard(achievement: a))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final accent = unlocked ? achievement.color : const Color(0xFF3A4456);

    return Container(
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF1A2332) : const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? achievement.color.withOpacity(0.4)
              : const Color(0x14FFFFFF),
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: achievement.color.withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? achievement.color.withOpacity(0.18)
                      : const Color(0x1AFFFFFF),
                ),
                child: Icon(
                  achievement.icon,
                  color: accent,
                  size: 22,
                ),
              ),
              Icon(
                unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: unlocked ? achievement.color : const Color(0xFF4B5563),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              achievement.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (unlocked)
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 13, color: achievement.color),
                const SizedBox(width: 4),
                Text(
                  'Unlocked',
                  style: TextStyle(
                    color: achievement.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: achievement.progress,
                minHeight: 5,
                backgroundColor: const Color(0x14FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  RouticaTheme.accent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.progressLabel,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
