import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controller for the logo drop-in and fade-in
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Continuous controller for the background shapes/orbs. repeat() is
    // started from didChangeDependencies below, gated on reduce-motion.
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _mainController.forward();

    _navigateWhenReady();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative background shapes/orbs — respects reduce-motion.
    _bgController.repeatUnlessReducedMotion(context);
  }

  /// Was a flat `Timer(3000ms)` regardless of whether the app was actually
  /// ready — meaning a slow cold start (DB init, migrations) still handed
  /// the user off to a half-ready MainShell after exactly 3s, while a fast
  /// one made them wait out 3s for nothing. Gate on the same read MainShell
  /// itself waits on (onboardingDoneProvider), with a floor no longer than
  /// the entry animation so the brand moment isn't cut short on a fast
  /// device, and no explicit ceiling — if it's still not ready, the user
  /// sees the (branded) splash animation continue rather than a jump into
  /// broken content.
  Future<void> _navigateWhenReady() async {
    await Future.wait<bool>([
      ref.read(onboardingDoneProvider.future).catchError((_) => false),
      Future.delayed(_mainController.duration!, () => false),
    ]);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // ── Geometric Background (Shared) ──
          const CustomPatternBackground(pattern: BackgroundPattern.adhkar),

          // ── Gradient Glows ──
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.teal.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.gold.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ──
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Container with soft dynamic glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft Glow behind logo
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: context.colors.gold.withValues(alpha: 0.25),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),

                            // The transparent animated logo
                            Image.asset(
                              'assets/images/takwa_transparent_bg.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        const SizedBox(height: AppSpacing.xxl),

                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: _VerseCard(
                            verse: '﴿ حاسبوا أنفسكم قبل أن تُحاسبوا﴾',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final String verse;
  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0x1CC8A96E), Color(0x0E3AAFA9)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 1,
                color: context.colors.gold.withValues(alpha: 0.3),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '❁',
                style: TextStyle(color: context.colors.gold, fontSize: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 28,
                height: 1,
                color: context.colors.gold.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            verse,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: context.colors.gold,
              height: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
