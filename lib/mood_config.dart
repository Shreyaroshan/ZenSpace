import 'package:flutter/material.dart';

/// Single source of truth for all mood-related data.
/// DB column is [mood_score] with values 1–5.
class MoodConfig {
  static const Map<int, Map<String, dynamic>> moodMap = {
    1: {'label': 'Awful',   'emoji': '😞', 'color': Color(0xFFEF4444)},
    2: {'label': 'Bad',     'emoji': '😟', 'color': Color(0xFFF97316)},
    3: {'label': 'Okay',    'emoji': '😐', 'color': Color(0xFFF59E0B)},
    4: {'label': 'Good',    'emoji': '🙂', 'color': Color(0xFF10B981)},
    5: {'label': 'Amazing', 'emoji': '😄', 'color': Color(0xFF6366F1)},
  };

  static String getMoodLabel(int score) =>
      (moodMap[score]?['label'] as String?) ?? 'Unknown';

  static String getMoodEmoji(int score) =>
      (moodMap[score]?['emoji'] as String?) ?? '😐';

  static Color getMoodColor(int score) =>
      (moodMap[score]?['color'] as Color?) ?? const Color(0xFF9CA3AF);
}