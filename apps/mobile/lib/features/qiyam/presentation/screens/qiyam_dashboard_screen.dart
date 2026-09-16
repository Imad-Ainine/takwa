import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/features/qiyam/domain/models/qiyam_session.dart';
import 'package:takwa/features/qiyam/providers/qiyam_providers.dart';
import 'package:takwa/app/main_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import 'package:takwa/app/animated_drawer.dart';
import '../../../../core/widgets/takwa_loading_indicator.dart';
import '../../../../core/widgets/takwa_tappable.dart';
import '../widgets/qiyam_onboarding_overlay.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamDashboardScreen extends ConsumerStatefulWidget {
  const QiyamDashboardScreen({super.key});

  @override
  ConsumerState<QiyamDashboardScreen> createState() =>
      _QiyamDashboardScreenState();
}

class _QiyamDashboardScreenState extends ConsumerState<QiyamDashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // See HomeScreen's _HomeScreenState for why: one of six MainShell tabs.
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AudioPlayer _audioPlayer;

  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, so it can be
    // gated on reduce-motion (needs a BuildContext, not meaningfully
    // available yet at this point in initState).
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _audioPlayer = AudioPlayer();

    // Trigger banner when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showBanner = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative breathing pulse — respects reduce-motion.
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  Future<void> _playWelcomeSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/ayah.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing welcome sound: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    // Listen to tab changes
    ref.listen(currentTabProvider, (prev, next) {
      if (next == 1) {
        // Trigger banner when switching to this tab
        if (mounted) {
          setState(() => _showBanner = true);
        }
      }
    });

    final session = ref.watch(qiyamSessionProvider);
    final onboardingDone =
        ref.watch(qiyamOnboardingDoneProvider).valueOrNull ?? true;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Background System
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, session),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPlanSelector(context, session),
                        const SizedBox(height: AppSpacing.xl),
                        _buildTimerRing(context, session),
                        const SizedBox(height: 40),
                        _buildStageInfo(context, session),
                        const SizedBox(height: AppSpacing.xl),
                        _buildControls(context, session),
                        const SizedBox(height: AppSpacing.xl),
                        _buildStoriesButton(context),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildToolsSection(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Banner Notification Overlay
          if (_showBanner && onboardingDone)
            _IntroBannerNotification(
              onDismiss: () => setState(() => _showBanner = false),
            ),

          // Onboarding Overlay
          if (!onboardingDone)
            const Positioned.fill(child: QiyamOnboardingOverlay()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QiyamSessionState session) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const DrawerMenuButton(),
          Column(
            children: [
              Text(
                l10n.qiyamDashboardTitle,
                style: context.typography.displayMedium.copyWith(
                  fontSize: 22,
                  color: context.colors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.qiyamDashboardStageProgress(
                  (session.currentStageIndex + 1).toString(),
                  session.stages.length.toString(),
                ),
                style: context.typography.caption.copyWith(
                  color: context.colors.textDim,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.qiyamCalculator),
            icon: Icon(Icons.calculate_outlined, color: context.colors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(BuildContext context, QiyamSessionState session) {
    final l10n = AppLocalizations.of(context)!;
    final durations = [5, 10, 15, 20, 30];
    final currentDuration = session.stages.first.defaultDuration.inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.qiyamDashboardChooseStageDuration,
            style: context.typography.caption.copyWith(
              fontSize: 20,
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: durations.map((mins) {
              final isSelected = currentDuration == mins;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(qiyamSessionProvider.notifier)
                        .updatePlanDuration(Duration(minutes: mins));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                context.colors.gold,
                                context.colors.teal,
                              ],
                            )
                          : null,
                      color: isSelected ? null : context.colors.card,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : context.colors.border,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.colors.gold.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      l10n.qiyamDashboardMinutesLabel(mins),
                      style: context.typography.bodyMedium.copyWith(
                        color: isSelected
                            ? context.colors.night
                            : context.colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRing(BuildContext context, QiyamSessionState session) {
    final l10n = AppLocalizations.of(context)!;
    final stage = session.currentStage;
    final progress =
        session.elapsed.inSeconds / stage.defaultDuration.inSeconds;

    return ScaleTransition(
      scale: _pulse,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: stage.color.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Circular Progress
          SizedBox(
            width: 240,
            height: 240,
            child: TakwaLoadingIndicator(
              size: 240,
              strokeWidth: 4,
              color: stage.color,
            ),
          ),
          // Main Circle Content
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.colors.card, context.colors.night],
              ),
              border: Border.all(color: stage.color.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stage.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatDuration(
                    (stage.defaultDuration - session.elapsed).isNegative
                        ? Duration.zero
                        : stage.defaultDuration - session.elapsed,
                  ),
                  style: context.typography.displayLarge.copyWith(
                    fontSize: 36,
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  l10n.qiyamDashboardTimeRemainingLabel,
                  style: context.typography.caption.copyWith(
                    color: context.colors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageInfo(BuildContext context, QiyamSessionState session) {
    final l10n = AppLocalizations.of(context)!;
    final stage = session.currentStage;
    return Column(
      children: [
        Text(
          qiyamStageTitle(l10n, stage.id),
          style: context.typography.displayMedium.copyWith(
            fontSize: 28,
            color: context.colors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          qiyamStageSubtitle(l10n, stage.id),
          style: context.typography.bodyLarge.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, QiyamSessionState session) {
    final isRunning = session.status == QiyamStageStatus.running;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Next
          _buildCircleButton(
            icon: Icons.skip_next,
            onPressed: () =>
                ref.read(qiyamSessionProvider.notifier).nextStage(),
          ),

          // Play/Pause
          TakwaTappable(
            onTap: () {
              final notifier = ref.read(qiyamSessionProvider.notifier);
              if (isRunning) {
                notifier.pauseSession();
              } else {
                notifier.startSession();
              }
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.colors.gold, context.colors.teal],
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.gold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isRunning ? Icons.pause : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Previous
          _buildCircleButton(
            icon: Icons.skip_previous,
            onPressed: () =>
                ref.read(qiyamSessionProvider.notifier).previousStage(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.border),
        ),
        child: Icon(icon, color: context.colors.textPrimary),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildStoriesButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, Routes.qiyamStories),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.gold.withValues(alpha: 0.15),
                  context.colors.teal.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPatternBackground(
                    pattern: BackgroundPattern.adhkar,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.gold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: context.colors.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.qiyamDashboardStoriesTitle,
                              style: context.typography.bodyLarge.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.qiyamDashboardStoriesSubtitle,
                              style: context.typography.caption.copyWith(
                                color: context.colors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        color: context.colors.gold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.qiyamDashboardToolsSectionTitle,
            style: context.typography.caption.copyWith(
              color: context.colors.textDim,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildToolCard(
              context,
              title: l10n.qiyamWirdTitle,
              icon: Icons.auto_awesome,
              color: context.colors.gold,
              onTap: () => Navigator.pushNamed(context, Routes.qiyamWird),
            ),
            _buildToolCard(
              context,
              title: l10n.qiyamDashboardVirtuesTool,
              icon: Icons.star_rounded,
              color: context.colors.teal,
              onTap: () => Navigator.pushNamed(context, Routes.qiyamVirtues),
            ),
            _buildToolCard(
              context,
              title: l10n.qiyamDashboardSleepCalcTool,
              icon: Icons.bedtime_outlined,
              color: Colors.indigoAccent,
              onTap: () =>
                  Navigator.pushNamed(context, Routes.qiyamSleepCalculator),
            ),
            _buildToolCard(
              context,
              title: l10n.qiyamDashboardSunnahTool,
              icon: Icons.history_edu,
              color: Colors.brown[400]!,
              onTap: () =>
                  Navigator.pushNamed(context, Routes.qiyamSunnahGuide),
            ),
            _buildToolCard(
              context,
              title: l10n.qiyamDashboardBeginnerGuideTool,
              icon: Icons.lightbulb_outline,
              color: context.colors.success,
              onTap: () =>
                  Navigator.pushNamed(context, Routes.qiyamBeginnerGuide),
            ),
            _buildToolCard(
              context,
              title: l10n.qiyamDashboardHourCalcTool,
              icon: Icons.timer_outlined,
              color: context.colors.goldDark,
              onTap: () => Navigator.pushNamed(context, Routes.qiyamCalculator),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPatternBackground(
                  pattern: BackgroundPattern.adhkar,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: context.typography.labelMedium.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBannerNotification extends StatefulWidget {
  final VoidCallback onDismiss;
  const _IntroBannerNotification({required this.onDismiss});

  @override
  State<_IntroBannerNotification> createState() =>
      _IntroBannerNotificationState();
}

class _IntroBannerNotificationState extends State<_IntroBannerNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    // Auto dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  void _handleDismiss() {
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.goldDim.withValues(alpha: 0.5),
                    context.colors.gold,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.gold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.qiyamDashboardBannerLabel,
                          style: context.typography.caption.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Text(
                          l10n.qiyamDashboardTitle,
                          style: context.typography.headingMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.background,
                          ),
                        ),
                        Text(
                          l10n.qiyamDashboardBannerDesc,
                          style: context.typography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.colors.background.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _handleDismiss,
                    icon: Icon(
                      Icons.close,
                      color: context.colors.background,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
