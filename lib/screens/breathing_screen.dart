import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../database_helper.dart';

enum BreathingPhase { inhale, hold, exhale, holdAfterExhale }

class BreathingTechnique {
  final String name;
  final String category;
  final String instructions;
  final String benefit;
  final Map<BreathingPhase, int> durations;
  final Color themeColor;

  const BreathingTechnique({
    required this.name,
    required this.category,
    required this.instructions,
    required this.benefit,
    required this.durations,
    required this.themeColor,
  });
}

const List<BreathingTechnique> kTechniques = [
  BreathingTechnique(
    name: 'Box Breathing',
    category: 'Focus & Stress Control',
    instructions: 'Inhale 4s → Hold 4s → Exhale 4s → Hold 4s',
    benefit: 'Creates mental stability and calm under pressure',
    durations: {
      BreathingPhase.inhale: 4,
      BreathingPhase.hold: 4,
      BreathingPhase.exhale: 4,
      BreathingPhase.holdAfterExhale: 4,
    },
    themeColor: Color(0xFF6366F1),
  ),
  BreathingTechnique(
    name: '4-7-8 Breathing',
    category: 'Sleep & Anxiety Relief',
    instructions: 'Inhale 4s (Nose) → Hold 7s → Exhale 8s (Mouth)',
    benefit: 'Slows heart rate and relaxes the body quickly',
    durations: {
      BreathingPhase.inhale: 4,
      BreathingPhase.hold: 7,
      BreathingPhase.exhale: 8,
    },
    themeColor: Color(0xFF10B981),
  ),
  BreathingTechnique(
    name: 'Diaphragmatic',
    category: 'Deep Relaxation',
    instructions: 'Hand on belly. Inhale (Belly rises) → Exhale slowly',
    benefit: 'Improves oxygen flow and reduces shallow breathing',
    durations: {
      BreathingPhase.inhale: 4,
      BreathingPhase.exhale: 6,
    },
    themeColor: Color(0xFF0EA5E9),
  ),
  BreathingTechnique(
    name: 'Alternate Nostril',
    category: 'Mental Clarity',
    instructions: 'Close right nostril, inhale left → Close left, exhale right',
    benefit: 'Common in yoga; helps calm and focus the mind',
    durations: {
      BreathingPhase.inhale: 4,
      BreathingPhase.hold: 2,
      BreathingPhase.exhale: 4,
    },
    themeColor: Color(0xFFF59E0B),
  ),
  BreathingTechnique(
    name: 'Pursed Lip',
    category: 'Breath Control',
    instructions: 'Inhale nose (2s) → Exhale pursed lips (4s)',
    benefit: 'Keeps airways open longer and improves efficiency',
    durations: {
      BreathingPhase.inhale: 2,
      BreathingPhase.exhale: 4,
    },
    themeColor: Color(0xFFEC4899),
  ),
];

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  
  BreathingTechnique _selectedTechnique = kTechniques[0];
  BreathingPhase _currentPhase = BreathingPhase.inhale;
  bool _isActive = false;
  int _phaseCountdown = 0;
  int _totalDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  void _startSession() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isActive = true;
      _totalDuration = 0;
      _currentPhase = BreathingPhase.inhale;
      _startPhase();
    });
  }

  void _stopSession() {
    HapticFeedback.lightImpact();
    
    // Log the session if it lasted more than 5 seconds
    if (_totalDuration > 5) {
      DatabaseHelper.instance.insertBreathingSession(_selectedTechnique.name, _totalDuration);
    }

    _timer?.cancel();
    _breathingController.stop();
    _breathingController.reset();
    setState(() {
      _isActive = false;
      _phaseCountdown = 0;
    });
  }

  void _startPhase() {
    final duration = _selectedTechnique.durations[_currentPhase] ?? 0;
    _phaseCountdown = duration;

    // Animation control
    if (_currentPhase == BreathingPhase.inhale) {
      _breathingController.duration = Duration(seconds: duration);
      _breathingController.forward();
    } else if (_currentPhase == BreathingPhase.exhale) {
      _breathingController.duration = Duration(seconds: duration);
      _breathingController.reverse();
    } else {
      _breathingController.stop();
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _totalDuration++;
        if (_phaseCountdown > 1) {
          _phaseCountdown--;
        } else {
          _timer?.cancel();
          _moveToNextPhase();
        }
      });
    });
  }

  void _moveToNextPhase() {
    final phases = _selectedTechnique.durations.keys.toList();
    int nextIndex = (phases.indexOf(_currentPhase) + 1) % phases.length;
    setState(() {
      _currentPhase = phases[nextIndex];
      _startPhase();
    });
  }

  String _getPhaseLabel() {
    if (!_isActive) return 'Ready';
    switch (_currentPhase) {
      case BreathingPhase.inhale: return 'Inhale';
      case BreathingPhase.hold:
      case BreathingPhase.holdAfterExhale: return 'Hold';
      case BreathingPhase.exhale: return 'Exhale';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Breathing', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937))),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                _selectedTechnique.name,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedTechnique.category,
                style: TextStyle(
                  color: _selectedTechnique.themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildTechniqueSelector(isDark),
              const SizedBox(height: 40),
              _buildBreathingVisualizer(isDark),
              const SizedBox(height: 40),
              _buildGuidanceCard(isDark),
              const SizedBox(height: 40),
              _buildControlButton(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: kTechniques.map((t) {
        bool isSelected = _selectedTechnique == t;
        return GestureDetector(
          onTap: _isActive ? null : () {
            setState(() {
              _selectedTechnique = t;
              _breathingController.reset();
            });
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? t.themeColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              boxShadow: !isSelected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)] : [],
              border: Border.all(
                color: isSelected ? Colors.white30 : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
              ),
            ),
            child: Text(
              t.name,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade600),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreathingVisualizer(bool isDark) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260 * _scaleAnimation.value,
                  height: 260 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedTechnique.themeColor.withOpacity(0.05),
                    border: Border.all(
                      color: _selectedTechnique.themeColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 160 * _scaleAnimation.value,
                  height: 160 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _selectedTechnique.themeColor.withOpacity(0.8),
                        _selectedTechnique.themeColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedTechnique.themeColor.withOpacity(0.3),
                        blurRadius: 30 * _scaleAnimation.value,
                        spreadRadius: 10 * _scaleAnimation.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isActive ? '$_phaseCountdown' : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              _getPhaseLabel(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidanceCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 20),
          const SizedBox(height: 12),
          Text(
            _selectedTechnique.instructions,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF4B5563),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Text(
            '✔️ ${_selectedTechnique.benefit}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTechnique.themeColor.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isActive ? _stopSession : _startSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isActive ? Colors.transparent : _selectedTechnique.themeColor,
          foregroundColor: _isActive ? (isDark ? Colors.white : const Color(0xFF1F2937)) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: _isActive ? (isDark ? Colors.white24 : Colors.grey.shade300) : Colors.transparent,
              width: 2,
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          _isActive ? 'STOP SESSION' : 'START SESSION',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
