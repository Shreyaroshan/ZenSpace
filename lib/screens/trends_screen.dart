import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';
import '../mood_config.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  int _selectedRange = 7;
  bool _isLoading = true;
  double _avgMood = 0.0;
  String _bestDay = '--';
  int _totalCheckIns = 0;
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _distribution = [];

  @override
  void initState() {
    super.initState();
    _fetchTrends();
  }

  Future<void> _fetchTrends() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: _selectedRange - 1));
      
      final entries = await DatabaseHelper.instance.getMoodsForRange(
        startDate.toIso8601String().substring(0, 10),
        now.toIso8601String().substring(0, 10),
      );

      // 1. Calculate Average & Total Check-ins
      if (entries.isNotEmpty) {
        double sum = 0;
        for (var e in entries) sum += (e['mood_score'] as int? ?? 0);
        _avgMood = sum / entries.length;
        _totalCheckIns = entries.length;

        // 2. Calculate Best Day (Day of week with highest avg)
        final Map<String, List<int>> dayScores = {};
        for (var e in entries) {
          final dayName = DateFormat('EEEE').format(DateTime.parse(e['date']));
          dayScores.putIfAbsent(dayName, () => []).add(e['mood_score'] as int);
        }
        
        String topDay = '--';
        double highestAvg = 0;
        dayScores.forEach((day, scores) {
          double avg = scores.reduce((a, b) => a + b) / scores.length;
          if (avg > highestAvg) {
            highestAvg = avg;
            topDay = day;
          }
        });
        _bestDay = topDay;
      } else {
        _avgMood = 0.0;
        _totalCheckIns = 0;
        _bestDay = '--';
      }

      // 3. Process Visual Chart Data (Always last 7 days for consistency)
      final List<Map<String, dynamic>> last7Days = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = date.toIso8601String().substring(0, 10);
        final entry = entries.firstWhere((e) => e['date'] == dateStr, orElse: () => {});
        
        last7Days.add({
          'day': DateFormat('E').format(date).substring(0, 1),
          'mood': entry.isNotEmpty ? (entry['mood_score'] as int? ?? 0) : 0,
        });
      }

      // 4. Process Distribution (Levels 1-5)
      final List<Map<String, dynamic>> distList = [];
      for (int level = 5; level >= 1; level--) {
        int count = entries.where((e) => e['mood_score'] == level).length;
        distList.add({
          'level': level,
          'count': count,
          'percent': entries.isEmpty ? 0.0 : count / entries.length,
        });
      }

      setState(() {
        _chartData = last7Days;
        _distribution = distList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching trends: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Trends')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightCards(isDark),
                    const SizedBox(height: 24),
                    _buildChartSection(isDark),
                    const SizedBox(height: 24),
                    _buildDistributionSection(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInsightCards(bool isDark) {
    String moodLabel = 'N/A';
    if (_avgMood > 0) {
      int rounded = _avgMood.round();
      moodLabel = '${MoodConfig.getMoodEmoji(rounded)} ${MoodConfig.getMoodLabel(rounded)}';
    }

    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            'Average Mood',
            _avgMood == 0 ? '--' : _avgMood.toStringAsFixed(1),
            moodLabel,
            const Color(0xFF6366F1),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            'Best Day',
            _bestDay,
            'Happiest time',
            const Color(0xFF10B981),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, String sub, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            value, 
            style: TextStyle(
              fontSize: value.length > 8 ? 18 : 22, 
              fontWeight: FontWeight.w900, 
              color: isDark ? Colors.white : const Color(0xFF1F2937)
            )
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              _buildRangeToggle(isDark),
            ],
          ),
          const SizedBox(height: 32),
          _buildBarChart(isDark),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '$_totalCheckIns check-ins in the last $_selectedRange days',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [7, 30].map((r) {
          bool selected = _selectedRange == r;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedRange = r);
              _fetchTrends();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? (isDark ? const Color(0xFF6366F1) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
              ),
              child: Text(
                '${r}d',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? (isDark ? Colors.white : const Color(0xFF6366F1)) : Colors.grey.shade500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _chartData.map((d) {
          int moodLevel = d['mood'] as int;
          // Reduced height from 80 to 65 to prevent overflow
          double height = moodLevel == 0 ? 5.0 : (moodLevel / 5) * 65.0;
          Color color = moodLevel == 0 ? Colors.grey.withOpacity(0.1) : MoodConfig.getMoodColor(moodLevel);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (moodLevel > 0)
                  Text(MoodConfig.getMoodEmoji(moodLevel), style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.6), color],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d['day'],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          ..._distribution.map((d) => _buildDistributionBar(d, isDark)),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(Map<String, dynamic> d, bool isDark) {
    int level = d['level'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(MoodConfig.getMoodEmoji(level), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              MoodConfig.getMoodLabel(level),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: d['percent'],
                minHeight: 8,
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(MoodConfig.getMoodColor(level)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${d['count']}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }
}
