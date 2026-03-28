import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseHelper.instance;
      final prefs = await SharedPreferences.getInstance();

      final moodEntries = await db.getAllMoodEntries();
      final journalCount = await db.getGratitudeCount();
      final breathingCount = await db.getBreathingSessionCount();
      final currentStreak = prefs.getInt('current_streak') ?? 0;
      final uniqueMoods = await db.getUniqueMoodScores();

      int? getHour(Map<String, dynamic> e) {
        final timeStr = e['created_at'] ?? e['date'];
        if (timeStr == null) return null;
        try {
          return DateTime.parse(timeStr).hour;
        } catch (_) {
          return null;
        }
      }

      final List<Map<String, dynamic>> data = [
        {
          'title': 'Early Bird',
          'description': 'Logged before 8 AM.',
          'icon': '🌅',
          'isUnlocked': moodEntries.any((e) {
            final h = getHour(e);
            return h != null && h < 8;
          }),
          'progress': moodEntries.any((e) {
            final h = getHour(e);
            return h != null && h < 8;
          }) ? 1.0 : 0.0,
          'color': const Color(0xFFFBBF24),
        },
        {
          'title': 'Gratitude Guru',
          'description': 'Written 10 entries.',
          'icon': '📓',
          'isUnlocked': journalCount >= 10,
          'progress': (journalCount / 10).clamp(0.0, 1.0),
          'color': const Color(0xFF8B5CF6),
        },
        {
          'title': 'Zen Master',
          'description': '5 breathing sessions.',
          'icon': '🧘',
          'isUnlocked': breathingCount >= 5,
          'progress': (breathingCount / 5).clamp(0.0, 1.0),
          'color': const Color(0xFF10B981),
        },
        {
          'title': 'Consistency',
          'description': '7 day log streak.',
          'icon': '🔥',
          'isUnlocked': currentStreak >= 7,
          'progress': (currentStreak / 7).clamp(0.0, 1.0),
          'color': const Color(0xFFEF4444),
        },
        {
          'title': 'Mood Explorer',
          'description': 'Used 5 mood types.',
          'icon': '🌈',
          'isUnlocked': uniqueMoods.length >= 5,
          'progress': (uniqueMoods.length / 5).clamp(0.0, 1.0),
          'color': const Color(0xFF3B82F6),
        },
        {
          'title': 'Night Owl',
          'description': 'Logged after 10 PM.',
          'icon': '🌙',
          'isUnlocked': moodEntries.any((e) {
            final h = getHour(e);
            return h != null && h >= 22;
          }),
          'progress': moodEntries.any((e) {
            final h = getHour(e);
            return h != null && h >= 22;
          }) ? 1.0 : 0.0,
          'color': const Color(0xFF6366F1),
        },
      ];

      if (mounted) {
        setState(() {
          _achievements = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Achievements load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Achievements',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAchievementData,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000), // Center and limit width on desktop
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200, // Balanced card width
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAchievementCard(context, _achievements[index]),
                          childCount: _achievements.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int unlockedCount = _achievements.where((a) => a['isUnlocked']).length;
    double percent = _achievements.isEmpty ? 0 : unlockedCount / _achievements.length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlockedCount / ${_achievements.length} Badges Earned',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Map<String, dynamic> achievement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isUnlocked = achievement['isUnlocked'];
    Color themeColor = isUnlocked ? achievement['color'] : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadgeIcon(achievement, isUnlocked, themeColor, isDark),
                  const SizedBox(height: 14),
                  Text(
                    achievement['title'],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? (isDark ? Colors.white : const Color(0xFF111827)) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                  ),
                  const Spacer(),
                  if (!isUnlocked) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement['progress'],
                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor.withOpacity(0.5)),
                        minHeight: 4,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: themeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('EARNED', style: TextStyle(color: themeColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                    ),
                  ],
                ],
              ),
            ),
            if (!isUnlocked)
              Positioned(top: 10, right: 10, child: Icon(Icons.lock_outline_rounded, size: 16, color: isDark ? Colors.white10 : Colors.grey.shade300)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(Map<String, dynamic> achievement, bool isUnlocked, Color themeColor, bool isDark) {
    return Container(
      width: 56,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? [themeColor.withOpacity(0.8), themeColor]
              : [isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200],
        ),
        boxShadow: isUnlocked ? [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
          child: Center(
            child: Text(achievement['icon'], style: TextStyle(fontSize: 24, color: isUnlocked ? null : (isDark ? Colors.white10 : Colors.grey.shade400))),
          ),
        ),
      ),
    );
  }
}
