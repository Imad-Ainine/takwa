import 'dart:math' as math;
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
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final s = AdaptiveStyle(context, isRamadan);

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
                    s.bg.withValues(alpha: 0.15),
                    s.bg.withValues(alpha: 0.92),
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
                  background: _AuthHeader(style: s, entryCtrl: _entryCtrl),
                  collapseMode: CollapseMode.pin,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    children: [
                      _anim(0, _buildGlassCard(s)),
                      const SizedBox(height: AppSpacing.xl),
                      _anim(1, _buildSeparator(s)),
                      const SizedBox(height: AppSpacing.lg),
                      _anim(2, _buildGoogleBtn(s)),
                      const SizedBox(height: 28),
                      _anim(
                        3,
                        TakwaTappable(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                          minTapSize: null,
                          child: Text(
                            l10n.authContinueAsGuest,
                            style: s.naskh(
                              13,
                              color: s.textSec,
                              weight: FontWeight.w600,
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
                color: Colors.black38,
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

  // ── Glassmorphism Form Card – Refined Islamic ──────────
  Widget _buildGlassCard(AdaptiveStyle s) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: s.bg.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: s.gold.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: s.gold.withValues(alpha: 0.09),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AutofillGroup(
            child: Column(
              children: [
                // ── Tab bar – elegant gold gradient ──
                Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: s.bg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: s.gold.withValues(alpha: 0.18),
                    ),
                  ),
                  child: TabBar(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicatorPadding: EdgeInsets.zero,
                    controller: _tabs,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [s.goldDark, s.gold],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: s.gold.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: s.textSec,
                    dividerColor: Colors.transparent,
                    labelStyle: s.naskh(13, weight: FontWeight.bold),
                    tabs: [
                      Tab(text: l10n.authSignInTab),
                      Tab(text: l10n.authSignUpTab),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Username field (sign-up only) ──
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
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
                        style: s,
                        focusNode: _userFocus,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // ── Email ──
                AuthField(
                  ctrl: _emailCtrl,
                  hint: l10n.authEmailHint,
                  icon: Icons.alternate_email_rounded,
                  style: s,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                ),
                const SizedBox(height: 14),

                // ── Password ──
                AuthField(
                  ctrl: _passCtrl,
                  hint: l10n.authPasswordHint,
                  icon: Icons.lock_outline_rounded,
                  style: s,
                  isPassword: true,
                  focusNode: _passFocus,
                  isLast: true,
                  onSubmit: _submitActiveTab,
                ),

                // ── Password strength (sign-up only) ──
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _tabs.index == 1 && _passCtrl.text.isNotEmpty
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PasswordStrengthBar(strength: _passStrength, style: s),
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
                        style: s.naskh(12, color: s.gold),
                      ),
                    ),
                  ),

                if (_error != null) _buildError(s),
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

  Widget _buildError(AdaptiveStyle s) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!, style: s.naskh(12, color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparator(AdaptiveStyle s) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: s.gold.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            l10n.authOrSeparator,
            style: s.naskh(12, color: s.textDim),
          ),
        ),
        Expanded(
          child: Divider(
            color: s.gold.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleBtn(AdaptiveStyle s) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: _loading ? null : _signInGoogle,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              color: s.bg.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: s.gold.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: s.gold.withValues(alpha: 0.06),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.authGoogleSignInButton,
                  style: s.naskh(14, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarFieldBg extends StatelessWidget {
  final AnimationController controller;
  final AdaptiveStyle style;
  const _StarFieldBg({required this.controller, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => CustomPaint(
        painter: _StarsPainter(progress: controller.value, gold: style.gold),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF050B2A), style.bg],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double progress;
  final Color gold;
  _StarsPainter({required this.progress, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    const count = 60;

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height * 0.6;
      final twinkle = math.sin((progress * math.pi * 2) + i * 0.7);
      final opacity = (0.2 + 0.5 * ((twinkle + 1) / 2)).clamp(0.0, 0.8);
      final radius = 1.0 + rng.nextDouble() * 1.4;

      paint.color = (i % 7 == 0 ? gold : Colors.white).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, baseY), radius, paint);
    }

    // Mosque silhouette hint at bottom of header
    final mPaint = Paint()
      ..color = gold.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height * 0.45;
    path.moveTo(0, h);
    path.lineTo(w * 0.3, h);
    path.lineTo(w * 0.3, h * 0.7);
    path.quadraticBezierTo(w * 0.5, h * 0.3, w * 0.7, h * 0.7);
    path.lineTo(w * 0.7, h);
    path.lineTo(w, h);
    canvas.drawPath(path, mPaint);
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.progress != progress;
}

class _AuthHeader extends StatelessWidget {
  final AdaptiveStyle style;
  final AnimationController entryCtrl;
  const _AuthHeader({required this.style, required this.entryCtrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            style.bg.withValues(alpha: 0.97),
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
                          style.gold.withValues(alpha: 0.18),
                          style.bg,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.gold.withValues(alpha: 0.42 * entryCtrl.value),
                          blurRadius: 32,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: style.gold.withValues(alpha: 0.55),
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
                shaderCallback: (bounds) => LinearGradient(
                  colors: [style.gold, style.gold],
                ).createShader(bounds),
                child: Text(
                  l10n.appName,
                  style: style
                      .amiri(48, weight: FontWeight.w800)
                      .copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.authTagline,
                style: context.typography.bodyLarge.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  GLOW PULSE WRAPPER
// ══════════════════════════════════════════════════════
class _GlowPulse extends StatefulWidget {
  final Widget child;
  const _GlowPulse({required this.child});
  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.32 * _ctrl.value),
              blurRadius: 32,
              spreadRadius: 10,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
