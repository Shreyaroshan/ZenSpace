import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../mood_config.dart';
import '../streak_helper.dart';
import '../main.dart'; // To access streak refresh logic

class MoodLoggerScreen extends StatefulWidget {
  const MoodLoggerScreen({super.key});

  @override
  State<MoodLoggerScreen> createState() => _MoodLoggerScreenState();
}

class _MoodLoggerScreenState extends State<MoodLoggerScreen>
    with TickerProviderStateMixin {
  int? _selectedMood;
  final TextEditingController _noteController = TextEditingController();
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scaleControllers = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _scaleAnimations = _scaleControllers.map((c) {
      return Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();
    
    _checkTodayMood();
  }

  Future<void> _checkTodayMood() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existingMood = await DatabaseHelper.instance.getMoodForDate(today);
    
    if (existingMood != null && mounted) {
      setState(() {
        int score = existingMood['mood_score'];
        _selectedMood = score - 1;
        _noteController.text = existingMood['note'] ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  void _onMoodTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedMood = index);
    _scaleControllers[index].forward().then((_) => _scaleControllers[index].reverse());
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) {
      _showSnackBar('Please select how you feel first.', const Color(0xFF1F2937));
      return;
    }

    HapticFeedback.mediumImpact();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final moodScore = _selectedMood! + 1;
    final note = _noteController.text.trim();

    try {
      await DatabaseHelper.instance.insertMood(today, moodScore, note.isEmpty ? null : note);
      
      // Update streak immediately after saving mood
      await StreakHelper.updateStreak();
      
      if (mounted) {
        _showSnackBar('Mood entry saved! Streak updated 🔥', const Color(0xFF10B981));
        // Refresh home screen stats
        homeRefreshNotifier.value++; 
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mood Log'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildDateBadge(isDark),
                  const SizedBox(height: 32),
                  _buildTitleSection(isDark),
                  const SizedBox(height: 32),
                  _buildMoodGrid(isDark),
                  const SizedBox(height: 40),
                  _buildNoteField(isDark),
                  const SizedBox(height: 48),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDateBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, MMM d').format(DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Check-in',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6366F1),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How is your mind feeling today?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          final isSelected = _selectedMood == i;
          final moodLevel = i + 1;
          final color = MoodConfig.getMoodColor(moodLevel);

          return GestureDetector(
            onTap: () => _onMoodTap(i),
            child: ScaleTransition(
              scale: _scaleAnimations[i],
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                      ] : [],
                    ),
                    child: Center(
                      child: Text(
                        MoodConfig.getMoodEmoji(moodLevel),
                        style: TextStyle(fontSize: isSelected ? 28 : 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    MoodConfig.getMoodLabel(moodLevel),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNoteField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reflection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Add a brief note about your day...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _saveMood,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          'Save Daily Entry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
