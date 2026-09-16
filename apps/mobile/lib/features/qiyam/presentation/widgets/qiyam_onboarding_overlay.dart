import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/qiyam/providers/qiyam_providers.dart';
import 'package:takwa/features/quran/utils/quran_helpers.dart' show localizedNumeral;
import 'package:takwa/l10n/app_localizations.dart';

class QiyamOnboardingOverlay extends ConsumerStatefulWidget {
  const QiyamOnboardingOverlay({super.key});

  @override
  ConsumerState<QiyamOnboardingOverlay> createState() =>
      _QiyamOnboardingOverlayState();
}

class _QiyamOnboardingOverlayState extends ConsumerState<QiyamOnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _audioPlayer = AudioPlayer();
    _controller.forward();
    _playAyah();
  }

  Future<void> _playAyah() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/ayah.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing ayah in onboarding: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(),
                const SizedBox(height: 40),
                _buildTitle(context),
                const SizedBox(height: AppSpacing.xl),
                _buildDescription(context),
                const SizedBox(height: 50),
                _buildSteps(context),
                const Spacer(),
                _buildStartButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [context.colors.gold, context.colors.goldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(child: Text('🌙', style: TextStyle(fontSize: 60))),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.qiyamOnboardingTitle,
      style: context.typography.displayMedium.copyWith(
        color: context.colors.gold,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.qiyamOnboardingDescription,
      style: context.typography.bodyLarge.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSteps(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildStepItem(context, localizedNumeral(context, 1), l10n.qiyamOnboardingStep1),
        _buildStepItem(context, localizedNumeral(context, 2), l10n.qiyamOnboardingStep2),
        _buildStepItem(context, localizedNumeral(context, 3), l10n.qiyamOnboardingStep3),
        _buildStepItem(context, localizedNumeral(context, 4), l10n.qiyamOnboardingStep4),
      ],
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.gold.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                number,
                style: context.typography.caption.copyWith(
                  color: context.colors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              text,
              style: context.typography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          ref.read(completeQiyamOnboardingProvider)();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.gold,
          foregroundColor: context.colors.night,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
        child: Text(
          l10n.qiyamOnboardingStartButton,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
