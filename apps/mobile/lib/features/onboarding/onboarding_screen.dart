import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/providers/database_providers.dart';
import '../../core/notifications/notifications_service.dart';
import '../../core/notifications/overlay_background_service.dart';
import '../../core/supabase/supabase_config.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ── Enum for current step ──
enum OnboardStep {
  intro1,
  intro2,
  intro3,
  location,
  notifications,
  overlay,
  background,
  gender,
  // plan,
}

// ── State handling ──
class OnboardState {
  final OnboardStep step;
  final String? gender;
  final bool loading;

  OnboardState({required this.step, this.gender, this.loading = false});

  OnboardState copyWith({OnboardStep? step, String? gender, bool? loading}) {
    return OnboardState(
      step: step ?? this.step,
      gender: gender ?? this.gender,
      loading: loading ?? this.loading,
    );
  }
}

class OnboardNotifier extends StateNotifier<OnboardState> {
  OnboardNotifier() : super(OnboardState(step: OnboardStep.intro1));

  void next() {
    final nextStep = _getNextStep(state.step);
    if (nextStep != null) {
      state = state.copyWith(step: nextStep);
    }
  }

  void skip() {
    // Some steps might have special skip logic, for now just go next
    next();
  }

  void selectGender(String g) => state = state.copyWith(gender: g);

  OnboardStep? _getNextStep(OnboardStep current) {
    const steps = OnboardStep.values;
    final idx = steps.indexOf(current);
    if (idx < steps.length - 1) return steps[idx + 1];
    return null;
  }
}

final onboardProvider = StateNotifierProvider<OnboardNotifier, OnboardState>((
  ref,
) {
  return OnboardNotifier();
});

// ── Main Screen ──
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardProvider);
    final notifier = ref.read(onboardProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Dynamic Background
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          // Content
          _buildStep(context, state, notifier, ref),

          // Header / Progress (Hidden for intro pages)
          if (!_isIntro(state.step))
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: _StepIndicator(current: state.step),
            ),
        ],
      ),
    );
  }

  bool _isIntro(OnboardStep step) =>
      step == OnboardStep.intro1 ||
      step == OnboardStep.intro2 ||
      step == OnboardStep.intro3;

  Widget _buildStep(
    BuildContext context,
    OnboardState state,
    OnboardNotifier notifier,
    WidgetRef ref,
  ) {
    switch (state.step) {
      case OnboardStep.intro1:
        return _IntroStep(data: _onboardPages[0], onNext: notifier.next);
      case OnboardStep.intro2:
        return _IntroStep(data: _onboardPages[1], onNext: notifier.next);
      case OnboardStep.intro3:
        return _IntroStep(data: _onboardPages[2], onNext: notifier.next);
      case OnboardStep.location:
        return _LocationStep(
          onAllow: () async {
            try {
              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) {
                // If service is disabled, prompt user to enable it
                if (!context.mounted) return;
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.onboardingGpsDisabledMessage,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 13,
                      ),
                    ),
                    action: SnackBarAction(
                      label: l10n.onboardingSettingsAction,
                      textColor: Colors.white,
                      onPressed: () {
                        Geolocator.openLocationSettings();
                      },
                    ),
                    backgroundColor: context.colors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
                return; // Wait for them to enable it, we don't proceed yet
              }

              final p = await Geolocator.requestPermission().timeout(
                const Duration(seconds: 15),
              );

              if (p == LocationPermission.deniedForever) {
                if (!context.mounted) return;
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.onboardingLocationPermissionDeniedMessage,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 13,
                      ),
                    ),
                    action: SnackBarAction(
                      label: l10n.onboardingSettingsAction,
                      textColor: Colors.white,
                      onPressed: () {
                        Geolocator.openAppSettings();
                      },
                    ),
                    backgroundColor: context.colors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
                return;
              }
              // We move forward even if denied or restricted (not forever), as long as it's not a permanent block that requires UI changes
              notifier.next();
            } catch (e) {
              notifier.next();
            }
          },
          onSkip: notifier.skip,
        );
      case OnboardStep.notifications:
        return _NotificationsStep(
          onAllow: () async {
            try {
              await NotificationsService.requestPermissions().timeout(
                const Duration(seconds: 20),
              );
              notifier.next();
            } catch (e) {
              notifier.next();
            }
          },
          onSkip: notifier.skip,
        );
      case OnboardStep.overlay:
        return _OverlayStep(
          onAllow: () async {
            // No longer wait for the full timeout. Trigger request and move on.
            // This prevents the "hanging" feeling if the system call is slow.
            try {
              OverlayBackgroundService.requestPermissions();
              // Give a tiny moment for the platform intent to fire, then go next.
              await Future.delayed(const Duration(milliseconds: 500));
              notifier.next();
            } catch (e) {
              notifier.next();
            }
          },
          onSkip: notifier.skip,
        );
      case OnboardStep.background:
        return _BackgroundStep(
          onAllow: () async {
            try {
              await NotificationsService.requestBackgroundPermission().timeout(
                const Duration(seconds: 15),
              );
              notifier.next();
            } catch (e) {
              notifier.next();
            }
          },
          onSkip: notifier.skip,
        );
      case OnboardStep.gender:
        return _GenderStep(
          selected: state.gender,
          onSelect: notifier.selectGender,
          onNext: () async {
            if (state.gender != null) {
              await ref.read(settingsDaoProvider).set('gender', state.gender!);
              try {
                await ref.read(supabaseServiceProvider).updateProfile({
                  'gender': state.gender,
                });
              } catch (e) {
                // Ignore error if offline
                developer.log(
                  'Error updating gender: $e',
                  name: 'OnboardingScreen',
                );
              }
            }
            await ref.read(settingsDaoProvider).set('onboardingDone', 'true');
            ref.invalidate(onboardingDoneProvider);
          },
          onSkip: () async {
            await ref.read(settingsDaoProvider).set('onboardingDone', 'true');
            ref.invalidate(onboardingDoneProvider);
          },
        );
      // case OnboardStep.plan:
      //   return _PlanStep(
      //     onStart: () async {
      //       await ref.read(settingsDaoProvider).set('onboardingDone', 'true');
      //       ref.invalidate(onboardingDoneProvider);
      //     },
      //   );
    }
  }
}

// ── Step Indicator ──
class _StepIndicator extends StatelessWidget {
  final OnboardStep current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const setupSteps = [
      OnboardStep.location,
      OnboardStep.notifications,
      OnboardStep.overlay,
      OnboardStep.background,
      OnboardStep.gender,
      // OnboardStep.plan,
    ];
    final idx = setupSteps.indexOf(current);
    if (idx == -1) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(setupSteps.length, (i) {
          final active = i <= idx;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? context.colors.gold : context.colors.border,
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: context.colors.gold.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── STEP 0: Intro Pages ──
class _IntroStep extends StatelessWidget {
  final _OnboardingPage data;
  final VoidCallback onNext;

  const _IntroStep({required this.data, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Expanded(
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 100)),
            ),
          ),
          _InfoCard(
            title: data.title(l10n),
            titleColor: context.colors.gold,
            subtitle: data.subtitle(l10n),
            hint: l10n.onboardingEditLaterHint,
            primaryLabel: l10n.onboardingContinueButton,
            onPrimary: () async => onNext(),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String Function(AppLocalizations) title, subtitle;
  final String emoji;
  const _OnboardingPage(this.title, this.subtitle, this.emoji);
}

final _onboardPages = [
  _OnboardingPage(
    (l10n) => l10n.onboardingIntro1Title,
    (l10n) => l10n.onboardingIntro1Subtitle,
    '🌙',
  ),
  _OnboardingPage(
    (l10n) => l10n.onboardingIntro2Title,
    (l10n) => l10n.onboardingIntro2Subtitle,
    '✅',
  ),
  _OnboardingPage(
    (l10n) => l10n.onboardingIntro3Title,
    (l10n) => l10n.onboardingIntro3Subtitle,
    '📊',
  ),
];

// ── STEP 1: Location ──
class _LocationStep extends StatelessWidget {
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;

  const _LocationStep({required this.onAllow, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _LocationIllustration(colors: context.colors),
                ),
              ),
            ),
          ),
          _InfoCard(
            title: l10n.onboardingLocationTitle,
            titleColor: context.colors.gold,
            subtitle: l10n.onboardingLocationSubtitle,
            hint: l10n.onboardingLocationHint,
            primaryLabel: l10n.onboardingLocationAllowButton,
            onPrimary: onAllow,
            skipLabel: l10n.onboardingSkipButton,
            onSkip: onSkip,
          ),
        ],
      ),
    );
  }
}

// ── STEP 2: Notifications ──
class _NotificationsStep extends StatefulWidget {
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;
  const _NotificationsStep({required this.onAllow, required this.onSkip});

  @override
  State<_NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<_NotificationsStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bellCtrl;

  @override
  void initState() {
    super.initState();
    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative ringing-bell wiggle — respects reduce-motion.
    _bellCtrl.repeatUnlessReducedMotion(
      context,
      min: 0,
      max: 1,
      period: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _bellCtrl,
                builder: (_, _) => Transform.rotate(
                  angle: math.sin(_bellCtrl.value * math.pi * 2) * 0.15,
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: CustomPaint(
                      painter: _BellIllustration(colors: context.colors),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _InfoCard(
            title: l10n.onboardingNotificationsTitle,
            titleColor: context.colors.gold,
            subtitle: l10n.onboardingNotificationsSubtitle,
            hint: l10n.onboardingNotificationsHint,
            primaryLabel: l10n.onboardingNotificationsAllowButton,
            primaryIcon: Icons.notifications_active_rounded,
            onPrimary: widget.onAllow,
            skipLabel: l10n.onboardingSkipButton,
            onSkip: widget.onSkip,
          ),
        ],
      ),
    );
  }
}

// ── STEP 3: Gender ──
class _GenderStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _GenderStep({
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.onboardingGenderTitle,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    color: context.colors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GenderCard(
                      label: l10n.onboardingGenderMale,
                      value: 'male',
                      emoji: '👳',
                      selected: selected == 'male',
                      onTap: () => onSelect('male'),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _GenderCard(
                      label: l10n.onboardingGenderFemale,
                      value: 'female',
                      emoji: '🧕',
                      selected: selected == 'female',
                      onTap: () => onSelect('female'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.goldDim,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: context.colors.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('ℹ️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.onboardingGenderInfoHint,
                            style: TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 11,
                              color: context.colors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BottomActions(
            primaryLabel: l10n.onboardingNextButton,
            onPrimary: selected != null ? onNext : null,
            skipLabel: l10n.onboardingSkipButton,
            onSkip: onSkip,
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatefulWidget {
  final String label, value, emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GenderCard> createState() => _GenderCardState();
}

class _GenderCardState extends State<_GenderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_GenderCard old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: widget.selected ? _scale : const AlwaysStoppedAnimation(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x30C8A96E), Color(0x183AAFA9)],
                  )
                : null,
            color: widget.selected ? null : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: widget.selected
                  ? context.colors.gold.withValues(alpha: 0.6)
                  : context.colors.border,
              width: widget.selected ? 2.5 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: context.colors.gold.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.selected
                      ? RadialGradient(
                          colors: [
                            context.colors.gold.withValues(alpha: 0.25),
                            context.colors.gold.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  color: widget.selected ? null : context.colors.card2,
                  border: Border.all(
                    color: widget.selected
                        ? context.colors.gold.withValues(alpha: 0.5)
                        : context.colors.border,
                    width: widget.selected ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  color: widget.selected
                      ? context.colors.gold
                      : context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: widget.selected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.colors.gold, context.colors.teal],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.gold.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: context.colors.night,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── STEP 4: Auth ──
class _AuthStep extends StatefulWidget {
  final void Function(String) onAuth;
  final VoidCallback onSkip;
  const _AuthStep({required this.onAuth, required this.onSkip});

  @override
  State<_AuthStep> createState() => _AuthStepState();
}

class _AuthStepState extends State<_AuthStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _anims = List.generate(5, (i) {
      final s = i * 0.1, e = (s + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget w) => FadeTransition(
    opacity: _anims[i.clamp(0, 4)],
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _ctrl,
              curve: Interval(
                i * 0.1,
                (i * 0.1 + 0.4).clamp(0, 1),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: w,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _anim(
              0,
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0x30C8A96E), Color(0x10C8A96E)],
                    ),
                    border: Border.all(
                      color: context.colors.gold.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.gold.withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 38)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _anim(
              1,
              Column(
                children: [
                  Text(
                    l10n.appName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      color: context.colors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.onboardingSignInSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _anim(
              2,
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    _BenefitRow('💾', l10n.onboardingBenefitSaveProgress),
                    const SizedBox(height: AppSpacing.sm),
                    _BenefitRow('🏆', l10n.onboardingBenefitCompete),
                    const SizedBox(height: AppSpacing.sm),
                    _BenefitRow('📊', l10n.onboardingBenefitStats),
                    const SizedBox(height: AppSpacing.sm),
                    _BenefitRow('🌙', l10n.onboardingBenefitSync),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _anim(
              4,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: GestureDetector(
                  onTap: widget.onSkip,
                  child: Text(
                    l10n.onboardingContinueWithoutAccount,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      color: context.colors.textDim,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String icon, label;
  const _BenefitRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 13,
          color: context.colors.textPrimary,
        ),
      ),
      const Spacer(),
      Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: context.colors.success,
      ),
    ],
  );
}

// ── STEP 5: Plan ──
class _PlanStep extends StatefulWidget {
  final Future<void> Function() onStart;
  const _PlanStep({required this.onStart});

  @override
  State<_PlanStep> createState() => _PlanStepState();
}

class _PlanStepState extends State<_PlanStep>
    with SingleTickerProviderStateMixin {
  String _selected = 'free';
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 72),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0, 0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 160,
                  child: CustomPaint(
                    painter: _PlanIllustration(colors: context.colors),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0.2, 0.7),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.onboardingChoosePlanTitle,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      color: context.colors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.onboardingChoosePlanSubtitle,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _ctrl,
                  curve: const Interval(0.3, 0.9),
                ),
                child: Column(
                  children: [
                    _PlanCard(
                      id: 'premium',
                      title: l10n.onboardingPremiumTitle,
                      desc: l10n.onboardingPremiumDesc,
                      badge: l10n.onboardingPremiumBadge,
                      badgeColor: context.colors.gold,
                      price: l10n.onboardingPremiumPrice,
                      features: [
                        l10n.onboardingPremiumFeature1,
                        l10n.onboardingPremiumFeature2,
                        l10n.onboardingPremiumFeature3,
                        l10n.onboardingPremiumFeature4,
                        l10n.onboardingPremiumFeature5,
                      ],
                      selected: _selected == 'premium',
                      onTap: () => setState(() => _selected = 'premium'),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      id: 'free',
                      title: l10n.onboardingFreeTitle,
                      desc: l10n.onboardingFreeDesc,
                      features: [
                        l10n.onboardingFreeFeature1,
                        l10n.onboardingFreeFeature2,
                        l10n.onboardingFreeFeature3,
                        l10n.onboardingFreeFeature4,
                      ],
                      selected: _selected == 'free',
                      onTap: () => setState(() => _selected = 'free'),
                    ),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0.6, 1.0),
              ),
              child: PrimaryButton(
                label: _selected == 'premium'
                    ? l10n.onboardingStartPremiumCta
                    : l10n.onboardingStartFreeCta,
                onTap: widget.onStart,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String id, title, desc;
  final List<String> features;
  final bool selected;
  final String? badge;
  final Color? badgeColor;
  final String? price;
  final VoidCallback onTap;

  const _PlanCard({
    required this.id,
    required this.title,
    required this.desc,
    required this.features,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    context.colors.gold.withValues(alpha: 0.12),
                    context.colors.teal.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: selected ? null : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? context.colors.gold.withValues(alpha: 0.5)
                : context.colors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? context.colors.gold : Colors.transparent,
                    border: Border.all(
                      color: selected ? context.colors.gold : context.colors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: context.colors.night,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? context.colors.gold).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: (badgeColor ?? context.colors.gold).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 10,
                        color: badgeColor ?? context.colors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (price != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    price!,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 11,
                      color: context.colors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              desc,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 11,
                color: context.colors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARED COMPONENTS ──
class _InfoCard extends StatelessWidget {
  final String title, subtitle, hint, primaryLabel;
  final Color titleColor;
  final Future<void> Function() onPrimary;
  final String? skipLabel;
  final VoidCallback? onSkip;
  final IconData? primaryIcon;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.primaryLabel,
    required this.onPrimary,
    required this.titleColor,
    this.skipLabel,
    this.onSkip,
    this.primaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 14,
              color: context.colors.textPrimary,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 11,
              color: context.colors.textDim,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: primaryLabel,
            icon: primaryIcon,
            onTap: onPrimary,
          ),
          if (skipLabel != null && onSkip != null) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                skipLabel!,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  color: context.colors.textDim,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? skipLabel;
  final VoidCallback? onSkip;

  const _BottomActions({
    required this.primaryLabel,
    required this.onPrimary,
    this.skipLabel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: primaryLabel,
          onTap: onPrimary != null ? () async => onPrimary!() : null,
        ),
        if (skipLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onSkip,
            child: Text(
              skipLabel!,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 13,
                color: context.colors.textDim,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ── CUSTOM PAINTERS ──
// Audit §M10: these used to paint from the static `AppColors` alias (which
// is always the *dark* palette — see app_theme.dart), so every onboarding
// illustration rendered dark-mode colors even when the device was in light
// mode. Each painter below now takes the resolved `AppColorsExtension` from
// its caller's `context.colors` instead, so onboarding matches whichever
// theme is active like the rest of the app.
class _OnboardBgPainter extends CustomPainter {
  final double t;
  final AppColorsExtension colors;
  _OnboardBgPainter({required this.t, required this.colors});

  static final _rng = math.Random(42);
  static List<Offset>? _stars;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colors.night,
    );

    _stars ??= List.generate(
      80,
      (_) => Offset(
        _rng.nextDouble() * size.width,
        _rng.nextDouble() * size.height,
      ),
    );

    for (int i = 0; i < _stars!.length; i++) {
      final op = 0.05 + 0.2 * ((math.sin(t * 2 * math.pi + i * 0.4) + 1) / 2);
      canvas.drawCircle(
        _stars![i],
        0.8 + _rng.nextDouble(),
        Paint()..color = colors.gold.withValues(alpha: op),
      );
    }

    final cx = size.width * 0.84, cy = size.height * 0.08;
    canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()..color = const Color(0xFFFFF3CC),
    );
    canvas.drawCircle(
      Offset(cx + 10, cy - 4),
      15,
      Paint()..color = colors.night,
    );

    canvas.drawCircle(
      Offset(size.width / 2, -60),
      200,
      Paint()
        ..shader =
            RadialGradient(
              colors: [colors.gold.withValues(alpha: 0.06), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: Offset(size.width / 2, -60), radius: 200),
            ),
    );
  }

  @override
  bool shouldRepaint(_OnboardBgPainter o) => o.t != t || o.colors != colors;
}

class _LocationIllustration extends CustomPainter {
  final AppColorsExtension colors;
  _LocationIllustration({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 20, cy), width: 120, height: 160),
      const Radius.circular(18),
    );
    canvas.drawRRect(phone, Paint()..color = colors.card);
    canvas.drawRRect(
      phone,
      Paint()
        ..color = colors.gold.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - 80 + i * 20, cy - 60),
        Offset(cx - 80 + i * 20, cy + 60),
        Paint()
          ..color = colors.border
          ..strokeWidth = 0.8,
      );
    }

    _drawPin(canvas, Offset(cx - 20, cy - 20), 16, colors.gold);
    _drawPin(canvas, Offset(cx + 10, cy + 20), 10, colors.teal);

    canvas.drawCircle(
      Offset(cx + 60, cy + 20),
      30,
      Paint()..color = colors.teal.withValues(alpha: 0.15),
    );
    canvas.drawCircle(
      Offset(cx + 60, cy + 20),
      30,
      Paint()
        ..color = colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawLine(
      Offset(cx + 60, cy + 20),
      Offset(cx + 60, cy + 6),
      Paint()
        ..color = colors.gold
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + 60, cy + 20),
      Offset(cx + 70, cy + 20),
      Paint()
        ..color = colors.textSecondary
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    final path = Path()
      ..moveTo(cx + 10, cy + 20)
      ..quadraticBezierTo(cx, cy, cx - 20, cy - 20);
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.gold.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawPin(Canvas canvas, Offset pos, double r, Color color) {
    canvas.drawCircle(pos, r, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawCircle(pos, r - 4, Paint()..color = color);
    canvas.drawCircle(pos, r - 8, Paint()..color = colors.night);
  }

  @override
  bool shouldRepaint(covariant _LocationIllustration o) => o.colors != colors;
}

class _BellIllustration extends CustomPainter {
  final AppColorsExtension colors;
  _BellIllustration({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    for (int i = 3; i >= 0; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        40.0 + i * 12,
        Paint()..color = colors.gold.withValues(alpha: 0.03 + i * 0.02),
      );
    }

    final bell = Path();
    bell.moveTo(cx, cy - 55);
    bell.quadraticBezierTo(cx + 55, cy - 40, cx + 55, cy + 20);
    bell.quadraticBezierTo(cx + 55, cy + 35, cx + 70, cy + 35);
    bell.lineTo(cx - 70, cy + 35);
    bell.quadraticBezierTo(cx - 55, cy + 35, cx - 55, cy + 20);
    bell.quadraticBezierTo(cx - 55, cy - 40, cx, cy - 55);
    bell.close();

    canvas.drawPath(bell, Paint()..color = colors.gold.withValues(alpha: 0.85));
    canvas.drawPath(
      bell,
      Paint()
        ..color = colors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(Offset(cx, cy + 44), 10, Paint()..color = colors.gold);
    canvas.drawLine(
      Offset(cx, cy + 35),
      Offset(cx, cy + 34),
      Paint()
        ..color = colors.goldLight
        ..strokeWidth = 3,
    );

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 58), width: 16, height: 12),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = colors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      Offset(cx + 44, cy - 44),
      20,
      Paint()..color = colors.teal,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx + 44 - tp.width / 2, cy - 44 - tp.height / 2));

    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx - 70, cy - 10),
          width: 20.0 + i * 12,
          height: 20.0 + i * 12,
        ),
        -math.pi / 4,
        -math.pi / 2,
        false,
        Paint()
          ..color = colors.teal.withValues(alpha: 0.4 - i * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BellIllustration o) => o.colors != colors;
}

class _PlanIllustration extends CustomPainter {
  final AppColorsExtension colors;
  _PlanIllustration({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 20), width: 80, height: 80),
        const Radius.circular(12),
      ),
      Paint()..color = colors.card,
    );
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 0.4 - math.pi;
      canvas.drawCircle(
        Offset(cx + 70 * math.cos(angle), cy + 30 * math.sin(angle)),
        12,
        Paint()..color = colors.gold.withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        Offset(cx + 70 * math.cos(angle), cy + 30 * math.sin(angle)),
        8,
        Paint()..color = colors.goldLight.withValues(alpha: 0.5),
      );
    }
    _drawStar(canvas, Offset(cx, cy - 50), 20, colors.gold);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.5;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlanIllustration o) => o.colors != colors;
}

// ── STEP: Overlay ──
class _OverlayStep extends StatefulWidget {
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;
  const _OverlayStep({required this.onAllow, required this.onSkip});

  @override
  State<_OverlayStep> createState() => _OverlayStepState();
}

class _OverlayStepState extends State<_OverlayStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative floating illustration — respects reduce-motion.
    _floatCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, _) => SizedBox(
                  width: 220,
                  height: 200,
                  child: CustomPaint(
                    painter: _OverlayIllustration(
                      progress: _floatCtrl.value,
                      colors: context.colors,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _InfoCard(
            title: AppLocalizations.of(context)!.onboardingOverlayTitle,
            titleColor: context.colors.teal,
            subtitle: AppLocalizations.of(context)!.onboardingOverlaySubtitle,
            hint: AppLocalizations.of(context)!.onboardingOverlayHint,
            primaryLabel: AppLocalizations.of(
              context,
            )!.onboardingOverlayAllowButton,
            primaryIcon: Icons.layers_outlined,
            onPrimary: widget.onAllow,
            skipLabel: AppLocalizations.of(context)!.onboardingSkipButton,
            onSkip: widget.onSkip,
          ),
        ],
      ),
    );
  }
}

class _OverlayIllustration extends CustomPainter {
  final double progress;
  final AppColorsExtension colors;
  _OverlayIllustration({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    // Background App
    final appRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 140, height: 100),
      const Radius.circular(12),
    );
    canvas.drawRRect(appRect, Paint()..color = colors.card);
    canvas.drawRRect(
      appRect,
      Paint()
        ..color = colors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Some dummy lines in the background app
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(cx - 50, cy - 10 + i * 15),
        Offset(cx + 50, cy - 10 + i * 15),
        Paint()..color = colors.border.withValues(alpha: 0.3),
      );
    }

    // Floating Overlay Window
    final floatY = cy - 20 - (progress * 15);
    final overlayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, floatY), width: 100, height: 60),
      const Radius.circular(10),
    );

    // Glow for overlay
    canvas.drawRRect(
      overlayRect.inflate(8),
      Paint()
        ..shader = RadialGradient(
          colors: [colors.gold.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, floatY), radius: 60)),
    );

    canvas.drawRRect(overlayRect, Paint()..color = colors.card);
    canvas.drawRRect(
      overlayRect,
      Paint()
        ..color = colors.gold.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Text in overlay
    final l10n = lookupAppLocalizations(const Locale('ar'));
    final tp = TextPainter(
      text: TextSpan(
        text: l10n.onboardingDemoTasbeehText,
        style: TextStyle(
          color: colors.gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, floatY - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _OverlayIllustration o) =>
      o.progress != progress || o.colors != colors;
}

// ── STEP: Background ──
class _BackgroundStep extends StatefulWidget {
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;
  const _BackgroundStep({required this.onAllow, required this.onSkip});

  @override
  State<_BackgroundStep> createState() => _BackgroundStepState();
}

class _BackgroundStepState extends State<_BackgroundStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative breathing pulse — respects reduce-motion.
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => SizedBox(
                  width: 220,
                  height: 200,
                  child: CustomPaint(
                    painter: _BackgroundIllustration(
                      progress: _pulseCtrl.value,
                      colors: context.colors,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _InfoCard(
            title: AppLocalizations.of(context)!.onboardingBackgroundTitle,
            titleColor: context.colors.gold,
            subtitle: AppLocalizations.of(
              context,
            )!.onboardingBackgroundSubtitle,
            hint: AppLocalizations.of(context)!.onboardingBackgroundHint,
            primaryLabel: AppLocalizations.of(
              context,
            )!.onboardingBackgroundAllowButton,
            primaryIcon: Icons.battery_saver_rounded,
            onPrimary: widget.onAllow,
            skipLabel: AppLocalizations.of(context)!.onboardingSkipButton,
            onSkip: widget.onSkip,
          ),
        ],
      ),
    );
  }
}

class _BackgroundIllustration extends CustomPainter {
  final double progress;
  final AppColorsExtension colors;
  _BackgroundIllustration({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    // Pulse rings
    for (int i = 0; i < 3; i++) {
      final r = 60.0 + (i * 30.0) + (progress * 20.0);
      final opacity = (0.05 - (i * 0.015)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = colors.teal.withValues(alpha: opacity),
      );
    }

    // Phone shape
    const phoneWidth = 80.0, phoneHeight = 140.0;
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: phoneWidth,
        height: phoneHeight,
      ),
      const Radius.circular(16),
    );

    // Background glow
    canvas.drawRRect(
      phoneRect.inflate(10),
      Paint()
        ..shader = RadialGradient(
          colors: [colors.teal.withValues(alpha: 0.2), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 100)),
    );

    canvas.drawRRect(phoneRect, Paint()..color = colors.card);
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..color = colors.teal.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Battery icon inside
    final batteryRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 30,
      height: 50,
    );
    final batteryPaint = Paint()..color = colors.teal.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(batteryRect, const Radius.circular(4)),
      batteryPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Battery tip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 5, cy - 25 - 4, 10, 4),
        const Radius.circular(2),
      ),
      batteryPaint..style = PaintingStyle.fill,
    );

    // Filling battery based on pulse
    final fillHeight = 10.0 + (progress * 30.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          batteryRect.left + 4,
          batteryRect.bottom - 4 - fillHeight,
          batteryRect.right - 4,
          batteryRect.bottom - 4,
        ),
        const Radius.circular(2),
      ),
      batteryPaint..color = colors.teal.withValues(alpha: 0.5 + (0.5 * progress)),
    );

    // Gear icons around signifying background services
    _drawSmallGear(canvas, Offset(cx - 60, cy - 40), 12, progress * math.pi);
    _drawSmallGear(canvas, Offset(cx + 60, cy + 30), 10, -progress * math.pi);
  }

  void _drawSmallGear(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    final paint = Paint()
      ..color = colors.gold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawCircle(Offset.zero, radius * 0.6, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          math.cos(angle) * (radius * 0.7),
          math.sin(angle) * (radius * 0.7),
        ),
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundIllustration o) =>
      o.progress != progress || o.colors != colors;
}
