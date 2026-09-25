import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;
  late final AnimationController _entryCtrl;
  late final AnimationController _bgCtrl; // rotating star field
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _loading = false;
  String? _error;
  double _passStrength = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
    _passCtrl.addListener(_updatePassStrength);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative rotating star field — respects reduce-motion.
    _bgCtrl.repeatUnlessReducedMotion(context);
  }

  void _updatePassStrength() {
    final p = _passCtrl.text;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9!@#\$%^&*]'))) s += 0.25;
    setState(() => _passStrength = s);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    _userFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _submitActiveTab() {
    if (_loading) return;
    if (_tabs.index == 0) {
      _signIn();
    } else {
      _signUp();
    }
  }

  Future<void> _syncGender() async {
    try {
      final gender = await ref.read(settingsDaoProvider).get('gender');
      if (gender != null) {
        await ref.read(supabaseServiceProvider).updateProfile({
          'gender': gender,
        });
      }
    } catch (e) {
      debugPrint('Error syncing gender: $e');
    }
  }

  // ── Actions ──────────────────────────────────────────
  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = l10n.authEnterEmailPassword);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      await _syncGender();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _authError(l10n, e.message));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.authUnexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_userCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.authEnterUsername);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = l10n.authEnterEmailPassword);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseServiceProvider)
          .signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            username: _userCtrl.text.trim(),
          );
      await _syncGender();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.emailConfirmation,
          arguments: _emailCtrl.text.trim(),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _authError(l10n, e.message));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.authUnexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(supabaseServiceProvider).signInWithGoogle();
      if (res != null) {
        await _syncGender();
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      final errStr = e.toString();
      if (errStr.contains('ApiException: 10') ||
          errStr.contains('DEVELOPER_ERROR')) {
        if (mounted) {
          setState(() => _error = l10n.authGoogleConfigIncomplete);
        }
      } else if (errStr.contains('network') ||
          errStr.contains('SocketException')) {
        if (mounted) {
          setState(() => _error = l10n.authGoogleNetworkError);
        }
      } else if (errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('user_cancelled')) {
        // Canceled by user - do not display error
      } else {
        if (mounted) {
          setState(() => _error = l10n.authGoogleGenericError);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForgotPassword() {
    Navigator.pushNamed(
      context,
      Routes.forgotPassword,
      arguments: _emailCtrl.text.trim(),
    );
  }

  String _authError(AppLocalizations l10n, String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid_grant')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (lower.contains('email not confirmed')) {
      return l10n.authErrorEmailNotConfirmed;
    }
    if (lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return l10n.authErrorEmailAlreadyRegistered;
    }
    if (lower.contains('unique constraint') || lower.contains('username')) {
      return l10n.authErrorUsernameTaken;
    }
    if (lower.contains('password should')) {
      return l10n.authErrorPasswordTooShort;
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return l10n.authErrorRateLimit;
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return l10n.authErrorNetwork;
    }
    return l10n.authErrorGeneric;
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Scaffold(
      body: Stack(
        children: [
          // Soft geometric pattern
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          // Soft gradient wash for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0.15),
                    colors.background.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // ② Scroll content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 290,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _AuthHeader(entryCtrl: _entryCtrl),
                  collapseMode: CollapseMode.pin,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    100,
                  ),
                  child: Column(
                    children: [
                      _anim(0, _buildGlassCard()),
                      const SizedBox(height: AppSpacing.xl),
                      _anim(1, _buildSeparator()),
                      const SizedBox(height: AppSpacing.lg),
                      _anim(2, _buildGoogleBtn()),
                      const SizedBox(height: AppSpacing.xxl),
                      _anim(
                        3,
                        TakwaTappable(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                          minTapSize: null,
                          child: Text(
                            l10n.authContinueAsGuest,
                            style: context.typography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ③ Loading overlay
          if (_loading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: colors.overlay,
                child: const TakwaLoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _anim(int i, Widget child) {
    final delay = i * 0.12;
    final end = (delay + 0.5).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(delay, end, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _entryCtrl,
                curve: Interval(delay, end, curve: Curves.easeOutCubic),
              ),
            ),
        child: child,
      ),
    );
  }

  // AuthField/PasswordStrengthBar still take a legacy AdaptiveStyle slot;
  // it reads whichever theme extension is active, so Ramadan styling is
  // preserved without threading `s` through the builders.
  AdaptiveStyle get style => AdaptiveStyle(context, false);

  // ── Glassmorphism Form Card – Refined Islamic ──────────
  Widget _buildGlassCard() {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: colors.gold.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.gold.withValues(alpha: 0.09),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              ...AppShadows.card,
            ],
          ),
          child: AutofillGroup(
            child: Column(
              children: [
                // ── Tab bar – elegant gold gradient ──
                Container(
                  height: 52,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.18),
                    ),
                  ),
                  child: TabBar(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicatorPadding: EdgeInsets.zero,
                    controller: _tabs,
                    indicator: BoxDecoration(
                      gradient: colors.goldGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: AppShadows.goldGlow,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: colors.textPrimary,
                    unselectedLabelColor: colors.textSecondary,
                    dividerColor: Colors.transparent,
                    labelStyle: typography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(text: l10n.authSignInTab),
                      Tab(text: l10n.authSignUpTab),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Username field (sign-up only) ──
                AnimatedCrossFade(
                  duration: AppMotion.fast,
                  crossFadeState: _tabs.index == 1
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      AuthField(
                        ctrl: _userCtrl,
                        hint: l10n.authUsernameHint,
                        icon: Icons.person_outline_rounded,
                        style: style,
                        focusNode: _userFocus,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // ── Email ──
                AuthField(
                  ctrl: _emailCtrl,
                  hint: l10n.authEmailHint,
                  icon: Icons.alternate_email_rounded,
                  style: style,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Password ──
                AuthField(
                  ctrl: _passCtrl,
                  hint: l10n.authPasswordHint,
                  icon: Icons.lock_outline_rounded,
                  style: style,
                  isPassword: true,
                  focusNode: _passFocus,
                  isLast: true,
                  onSubmit: _submitActiveTab,
                ),

                // ── Password strength (sign-up only) ──
                AnimatedCrossFade(
                  duration: AppMotion.fast,
                  crossFadeState: _tabs.index == 1 && _passCtrl.text.isNotEmpty
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: PasswordStrengthBar(
                      strength: _passStrength,
                      style: style,
                    ),
                  ),
                ),

                // ── Forgot password ──
                if (_tabs.index == 0)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      child: Text(
                        l10n.authForgotPassword,
                        style: typography.bodySmall.copyWith(
                          color: colors.goldText,
                        ),
                      ),
                    ),
                  ),

                if (_error != null) _buildError(),
                const SizedBox(height: AppSpacing.xl),

                // ── Submit ──
                PrimaryButton(
                  onTap: _loading ? null : _submitActiveTab,
                  label: _tabs.index == 0
                      ? l10n.authSecureSignInButton
                      : l10n.authCreateAccountButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.dangerDim,
          borderRadius: AppRadius.card,
          border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colors.dangerText,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _error!,
                style: context.typography.bodySmall.copyWith(
                  color: colors.dangerText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.gold.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            l10n.authOrSeparator,
            style: context.typography.bodySmall.copyWith(
              color: colors.textDim,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colors.gold.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleBtn() {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: _loading ? null : _signInGoogle,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              color: colors.background.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Center(
              child: Text(
                l10n.authGoogleSignInButton,
                style: context.typography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final AnimationController entryCtrl;
  const _AuthHeader({required this.entryCtrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colors.background.withValues(alpha: 0.97),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Glowing logo with refined gold ring
              Hero(
                tag: 'app_logo',
                child: AnimatedBuilder(
                  animation: entryCtrl,
                  builder: (_, child) => Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.gold.withValues(alpha: 0.18),
                          colors.background,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.gold.withValues(
                            alpha: 0.42 * entryCtrl.value,
                          ),
                          blurRadius: 32,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: colors.gold.withValues(alpha: 0.55),
                        width: 1.6,
                      ),
                    ),
                    child: child,
                  ),
                  child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ShaderMask(
                shaderCallback: (bounds) =>
                    colors.goldGradient.createShader(bounds),
                child: Text(
                  l10n.appName,
                  style: context.typography.displayLarge.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.authTagline,
                style: context.typography.bodyLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
