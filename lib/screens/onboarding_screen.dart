import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSaving = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _continue() async {
    if (!_canContinue) return;
    HapticFeedback.mediumImpact();
    _nameFocusNode.unfocus();
    setState(() => _isSaving = true);

    // Save name and mark onboarding complete directly via SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _nameFocusNode.unfocus(),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      size: 36,
                      color: Color(0xFF6366F1),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'Welcome to\nZenSpace',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    'Your personal sanctuary for mental wellness.\nLet\'s start by getting to know you.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Field label
                  Text(
                    'What should we call you?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Name field
                  ValueListenableBuilder(
                    valueListenable: _nameController,
                    builder: (_, __, ___) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E2E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _nameController.text.isNotEmpty
                              ? const Color(0xFF6366F1).withOpacity(0.5)
                              : (isDark
                              ? Colors.white12
                              : const Color(0xFFE5E5EA)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _continue(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Shreya',
                          hintStyle: TextStyle(
                            color:
                            isDark ? Colors.white24 : Colors.black26,
                            fontWeight: FontWeight.w400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          border: InputBorder.none,
                          suffixIcon: _nameController.text.isNotEmpty
                              ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF6366F1), size: 20)
                              : null,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: _canContinue
                            ? const Color(0xFF6366F1)
                            : (isDark
                            ? Colors.white12
                            : const Color(0xFFD1D1D6)),
                        boxShadow: _canContinue
                            ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1)
                                .withOpacity(0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _canContinue ? _continue : null,
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get started',
                                  style: TextStyle(
                                    color: _canContinue
                                        ? Colors.white
                                        : (isDark
                                        ? Colors.white38
                                        : Colors.black26),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: _canContinue
                                      ? Colors.white
                                      : (isDark
                                      ? Colors.white38
                                      : Colors.black26),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Privacy note
                  Center(
                    child: Text(
                      '🔒  Your data stays on your device. Always.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}