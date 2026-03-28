import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class StreakHelper {
  static Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    
    final db = DatabaseHelper.instance;
    
    // Get all moods
    final allMoods = await db.getMoodsForRange('2000-01-01', todayStr);
    if (allMoods.isEmpty) {
      await prefs.setInt('current_streak', 0);
      return;
    }

    // Use a Set to ensure we only count unique days
    final Set<String> uniqueDates = {
      for (var e in allMoods) (e['date'] as String).substring(0, 10)
    };

    // Sort unique dates descending
    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    DateTime checkDate = today;

    // Check if user has logged today. If not, streak might still be active from yesterday.
    bool loggedToday = uniqueDates.contains(todayStr);
    if (!loggedToday) {
      // Check if logged yesterday
      final yesterdayStr = today.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (!uniqueDates.contains(yesterdayStr)) {
        await prefs.setInt('current_streak', 0);
        return;
      }
      // If logged yesterday but not today, streak continues (but today isn't counted yet)
      checkDate = today.subtract(const Duration(days: 1));
    }

    for (String dateStr in sortedDates) {
      final entryDate = DateTime.parse(dateStr);
      final diff = DateTime(checkDate.year, checkDate.month, checkDate.day)
          .difference(DateTime(entryDate.year, entryDate.month, entryDate.day))
          .inDays;

      if (diff == 0) {
        currentStreak++;
      } else if (diff == 1) {
        currentStreak++;
        checkDate = entryDate;
      } else {
        break; // Streak broken
      }
    }

    final longest = prefs.getInt('longest_streak') ?? 0;
    await prefs.setInt('current_streak', currentStreak);
    if (currentStreak > longest) {
      await prefs.setInt('longest_streak', currentStreak);
    }
  }
}
