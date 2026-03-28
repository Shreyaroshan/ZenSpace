import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../database_helper.dart';
import '../mood_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  String _userName = '';
  int _totalEntries = 0;
  int _journalCount = 0;
  int _badgeCount = 0;
  List<double> _weeklyValues = List.filled(7, 0.0);
  List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen for global refreshes (e.g. from MoodLogger)
    homeRefreshNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    homeRefreshNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt('current_streak') ?? 0;
      final userName = prefs.getString('user_name') ?? '';
      final totalEntries = await DatabaseHelper.instance.getTotalMoodCount();
      final journalEntries = await DatabaseHelper.instance.getGratitudeEntries();
      
      // Calculate unlocked badges
      final moodEntries = await DatabaseHelper.instance.getAllMoodEntries();
      final breathingCount = await DatabaseHelper.instance.getBreathingSessionCount();
      final uniqueMoods = await DatabaseHelper.instance.getUniqueMoodScores();
      
      int badges = 0;
      if (moodEntries.any((e) => DateTime.parse(e['created_at']).hour < 8)) badges++; // Early Bird
      if (journalEntries.length >= 10) badges++; // Gratitude Guru
      if (breathingCount >= 5) badges++; // Zen Master
      if (streak >= 7) badges++; // Consistency King
      if (uniqueMoods.length >= 5) badges++; // Mood Explorer
      if (moodEntries.any((e) => DateTime.parse(e['created_at']).hour >= 22)) badges++; // Night Owl

      // Last 7 days for the mini chart
      final now = DateTime.now();
      final weekEntries = await DatabaseHelper.instance.getRecentMoods(7);

      // Build a map of dateString → moodScore for quick lookup
      final Map<String, int> moodByDate = {
        for (final e in weekEntries)
          (e['date'] as String).substring(0, 10): (e['mood_score'] as int? ?? 0),
      };

      final List<double> weeklyValues = [];
      final List<String> dynamicLabels = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = date.toIso8601String().substring(0, 10);
        final score = moodByDate[key] ?? 0;
        weeklyValues.add(score == 0 ? 0.0 : score / 5.0);
        dynamicLabels.add(DateFormat('E').format(date).substring(0, 1));
      }

      if (mounted) {
        setState(() {
          _streak = streak;
          _userName = userName;
          _totalEntries = totalEntries;
          _journalCount = journalEntries.length;
          _badgeCount = badges;
          _weeklyValues = weeklyValues;
          _weekDays = dynamicLabels;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isDark),
                      const SizedBox(height: 20),
                      _buildAffirmationCard(isDark),
                      const SizedBox(height: 24),
                      _buildHeroCard(context),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Weekly Overview', isDark),
                      const SizedBox(height: 16),
                      _buildWeeklyChart(isDark),
                      const SizedBox(height: 28),
                      _buildSectionTitle('My Stats', isDark),
                      const SizedBox(height: 12),
                      _buildStreakRow(context, isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ZenSpace',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : const Color(0xFF1F2937),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAffirmationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
      ),
      child: const Row(
        children: [
          Text('✨', style: TextStyle(fontSize: 24)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              '"You are allowed to be both a masterpiece and a work in progress."',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check-in to track your mental well-being.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => TabSwitchNotification(1).dispatch(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Log Your Mood', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final v = _weeklyValues[i];
          return Column(
            children: [
              Container(
                width: 32,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: v == 0 ? 4 : 80 * v,
                  width: 32,
                  decoration: BoxDecoration(
                    gradient: v == 0 ? null : const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    color: v == 0 ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _weekDays[i],
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white30 : Colors.grey.shade400),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStreakRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, '🔥', '$_streak', 'Streak', const Color(0xFF6366F1), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, '✨', '$_badgeCount', 'Badges', const Color(0xFF10B981), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, '📓', '$_totalEntries', 'Logs', const Color(0xFFF59E0B), isDark)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey.shade400, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937), letterSpacing: -0.5),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty ? ', $_userName' : '';
    if (hour >= 5 && hour < 12) return 'Good morning$name 🌤';
    if (hour >= 12 && hour < 17) return 'Good afternoon$name ☀️';
    return 'Good evening$name 🌙';
  }
}
