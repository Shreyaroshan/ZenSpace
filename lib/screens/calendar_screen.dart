import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../mood_config.dart';
import '../main.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _allEntries = [];
  Map<int, Color> _dayMoodColors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await DatabaseHelper.instance.getMoodsForRange(
        DateTime(_focusedDay.year, _focusedDay.month, 1)
            .toIso8601String()
            .substring(0, 10),
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0)
            .toIso8601String()
            .substring(0, 10),
      );

      final Map<int, Color> colors = {};
      for (final entry in entries) {
        if (entry['date'] != null) {
          final date = DateTime.parse(entry['date'] as String);
          final score = (entry['mood_score'] as int?) ?? 3;
          colors[date.day] = MoodConfig.getMoodColor(score);
        }
      }

      setState(() {
        _allEntries = entries.reversed.toList();
        _dayMoodColors = colors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CalendarScreen fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calendar'),
        toolbarHeight: 48,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isDesktop 
                    ? _buildDesktopLayout(isDark)
                    : _buildMobileLayout(isDark),
                ),
              ),
            ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              _buildMonthHeader(isDark),
              const SizedBox(height: 10),
              _buildCalendarGrid(isDark),
              const SizedBox(height: 12),
              _buildLegend(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecentLogsTitle(isDark),
                const SizedBox(height: 10),
                Expanded(child: _buildLogsList(isDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Left Side: Calendar and Legend
          SizedBox(
            width: 450, // Fixed width for calendar on desktop
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(isDark),
                const SizedBox(height: 16),
                _buildCalendarGrid(isDark),
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // Scrollable Right Side: Recent Logs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecentLogsTitle(isDark),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildLogsList(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogsTitle(bool isDark) {
    return Text(
      'Recent Logs',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildLogsList(bool isDark) {
    if (_allEntries.isEmpty) return _buildEmptyState(isDark);
    
    return ListView.builder(
      itemCount: _allEntries.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) => _buildMoodListItem(_allEntries[index], isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 48,
                color: isDark ? Colors.white10 : Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              'No entries for this month yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            color: const Color(0xFF6366F1),
            onPressed: () {
              setState(() => _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month - 1));
              _fetchData();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            color: const Color(0xFF6366F1),
            onPressed: () {
              setState(() => _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month + 1));
              _fetchData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade400),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 42,
            itemBuilder: (_, i) {
              final day = i - (firstWeekday - 1) + 1;
              if (day <= 0 || day > daysInMonth) return const SizedBox();

              final color = _dayMoodColors[day];
              final isToday = day == DateTime.now().day &&
                  _focusedDay.month == DateTime.now().month &&
                  _focusedDay.year == DateTime.now().year;

              return Container(
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: const Color(0xFF6366F1), width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: color ?? (isDark ? Colors.white70 : const Color(0xFF1F2937)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: MoodConfig.moodMap.values.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              item['label'] as String,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMoodListItem(Map<String, dynamic> m, bool isDark) {
    final score = (m['mood_score'] as int?) ?? 3;
    final color = MoodConfig.getMoodColor(score);
    final emoji = MoodConfig.getMoodEmoji(score);
    final label = MoodConfig.getMoodLabel(score);
    final date = DateTime.parse(m['date'] as String? ?? DateTime.now().toIso8601String());
    final int id = m['id'] as int;

    return Dismissible(
      key: Key('mood_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) async {
        await DatabaseHelper.instance.deleteMood(id);
        _fetchData();
        homeRefreshNotifier.value++;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMM d').format(date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  if (m['note'] != null && (m['note'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      m['note'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_back_rounded, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
