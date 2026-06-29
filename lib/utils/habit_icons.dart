import 'package:flutter/material.dart';

/// Single source of truth for icon-id → IconData mapping.
///
/// Previously the same 50-case switch was duplicated in
/// `habit_form_screen.dart` and `enhanced_habit_card.dart`.
/// Adding a new icon required updating both copies.  Now every
/// screen imports this single map.
class HabitIcons {
  HabitIcons._();

  static const Map<String, List<String>> iconGroups = {
    'Health & Fitness': [
      'dumbbell', 'bike', 'heart', 'activity', 'apple', 'water',
    ],
    'Learning & Work': [
      'brain', 'book', 'code', 'briefcase', 'pencil', 'graduation',
    ],
    'Lifestyle': [
      'coffee', 'music', 'home', 'palette', 'camera', 'game',
    ],
    'Nature & Environment': [
      'leaf', 'mountain', 'wind', 'sun', 'moon', 'plant',
    ],
    'Food & Nutrition': [
      'pizza', 'salad', 'soup', 'sandwich', 'utensils', 'cookie',
    ],
    'Motivation & Goals': [
      'star', 'award', 'trending', 'target', 'check', 'sparkles',
    ],
    'Time & Schedule': [
      'clock', 'schedule', 'calendar', 'zap', 'flame', 'hourglass',
    ],
    'Social & People': [
      'users', 'smile', 'handshake', 'family', 'social', 'globe',
    ],
  };

  static const List<String> allIconIds = [
    'dumbbell', 'bike', 'heart', 'activity', 'apple', 'water',
    'brain', 'book', 'code', 'briefcase', 'pencil', 'graduation',
    'coffee', 'music', 'home', 'palette', 'camera', 'game',
    'leaf', 'mountain', 'wind', 'sun', 'moon', 'plant',
    'pizza', 'salad', 'soup', 'sandwich', 'utensils', 'cookie',
    'star', 'award', 'trending', 'target', 'check', 'sparkles',
    'clock', 'schedule', 'calendar', 'zap', 'flame', 'hourglass',
    'users', 'smile', 'handshake', 'family', 'social', 'globe',
    'droplet', 'light',
  ];

  static IconData iconForId(String id) {
    return _map[id] ?? Icons.lightbulb_outline;
  }

  static const Map<String, IconData> _map = {
    'brain': Icons.lightbulb_outline,
    'dumbbell': Icons.fitness_center,
    'book': Icons.book,
    'droplet': Icons.water,
    'code': Icons.code,
    'heart': Icons.favorite,
    'coffee': Icons.local_cafe,
    'music': Icons.music_note,
    'bike': Icons.directions_bike,
    'camera': Icons.camera,
    'palette': Icons.palette,
    'flame': Icons.local_fire_department,
    'moon': Icons.dark_mode,
    'sun': Icons.light_mode,
    'zap': Icons.bolt,
    'target': Icons.location_on,
    'pencil': Icons.edit,
    'smile': Icons.sentiment_satisfied,
    'star': Icons.star,
    'trending': Icons.trending_up,
    'award': Icons.emoji_events,
    'clock': Icons.schedule,
    'check': Icons.check,
    'activity': Icons.directions_run,
    'briefcase': Icons.work,
    'gift': Icons.card_giftcard,
    'home': Icons.home,
    'leaf': Icons.eco,
    'mountain': Icons.terrain,
    'sparkles': Icons.star,
    'users': Icons.people,
    'wind': Icons.cloud,
    'apple': Icons.apple,
    'cookie': Icons.fastfood,
    'pizza': Icons.local_pizza,
    'sandwich': Icons.lunch_dining,
    'salad': Icons.restaurant,
    'soup': Icons.restaurant,
    'water': Icons.water_drop,
    'graduation': Icons.school,
    'game': Icons.sports_esports,
    'plant': Icons.nature,
    'utensils': Icons.dinner_dining,
    'schedule': Icons.event_note,
    'calendar': Icons.calendar_today,
    'hourglass': Icons.hourglass_empty,
    'handshake': Icons.handshake,
    'family': Icons.family_restroom,
    'social': Icons.group,
    'globe': Icons.public,
    'light': Icons.lightbulb,
  };
}
