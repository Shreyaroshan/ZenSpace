import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/mood_logger_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/onboarding_screen.dart';
import 'database_helper.dart';
import 'streak_helper.dart';

/// Dispatch this from any child widget to switch the bottom nav tab.
class TabSwitchNotification extends Notification {
  final int index;
  TabSwitchNotification(this.index);
}

/// Global theme notifier.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Global refresh notifier to trigger UI updates across screens.
final ValueNotifier<int> homeRefreshNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up DB
  try {
    await DatabaseHelper.instance.database;
    debugPrint('✅ Database initialised');
  } catch (e) {
    debugPrint('❌ Database init error: $e');
  }

  // Initial streak calculation on launch
  await StreakHelper.updateStreak();

  // Check onboarding flag directly via SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(ZenSpaceApp(showOnboarding: !onboardingDone));
}

class ZenSpaceApp extends StatelessWidget {
  final bool showOnboarding;

  const ZenSpaceApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          title: 'ZenSpace',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
            fontFamily: 'SF Pro Display',
            scaffoldBackgroundColor: const Color(0xFFFBFBFE),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              iconTheme: IconThemeData(color: Color(0xFF1F2937)),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF818CF8),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E2E),
            ),
            fontFamily: 'SF Pro Display',
            scaffoldBackgroundColor: const Color(0xFF161622),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          home: showOnboarding
              ? const OnboardingScreen()
              : const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MoodLoggerScreen(),
    BreathingScreen(),
    CalendarScreen(),
    TrendsScreen(),
    JournalScreen(),
    AchievementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationListener<TabSwitchNotification>(
      onNotification: (n) {
        setState(() => _currentIndex = n.index);
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _screens[_currentIndex],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            height: 72,
            backgroundColor:
            isDark ? const Color(0xFF1E1E2E) : Colors.white,
            indicatorColor: const Color(0xFF6366F1).withOpacity(0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.sentiment_satisfied_alt_outlined),
                selectedIcon: Icon(Icons.sentiment_satisfied_alt_rounded),
                label: 'Mood',
              ),
              NavigationDestination(
                icon: Icon(Icons.air_rounded),
                selectedIcon: Icon(Icons.air_rounded),
                label: 'Breathe',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Trends',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                selectedIcon: Icon(Icons.auto_stories_rounded),
                label: 'Journal',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events_rounded),
                label: 'Badges',
              ),
            ],
          ),
        ),
      ),
    );
  }
}