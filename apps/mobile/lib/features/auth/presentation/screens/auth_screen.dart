import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_success_overlay.dart';
import 'package:takwa/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;
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
    _passCtrl.addListener(_updatePassStrength);
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
      if (mounted) {
        setState(() => _loading = false);
        await showAuthSuccess(context, label: l10n.authWelcomeBack);
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
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
        if (mounted) {
          setState(() => _loading = false);
          await showAuthSuccess(context, label: l10n.authWelcomeBack);
          if (mounted) Navigator.pushReplacementNamed(context, '/');
        }
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

  void _clearError(_) {
    if (_error != null) setState(() => _error = null);
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Stack(
      children: [
        AuthScaffold(
          children: [
            Hero(
              tag: 'app_logo',
              child: Center(child: AuthEmblem.moon(size: 94)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthGoldTitle(l10n.appName, fontSize: 44),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.authTagline,
              textAlign: TextAlign.center,
              style: context.typography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildGlassCard(l10n),
            const SizedBox(height: AppSpacing.xl),
            _buildSeparator(l10n),
            const SizedBox(height: AppSpacing.lg),
            _buildGoogleBtn(l10n),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: TakwaTappable(
                onTap: () => Navigator.pushReplacementNamed(context, '/'),
                minTapSize: null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.authContinueAsGuest,
                    style: context.typography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_loading) const Positioned.fill(child: AuthLoadingOverlay()),
      ],
    );
  }

  // AuthField/PasswordStrengthBar still take a legacy AdaptiveStyle slot;
  // it reads whichever theme extension is active, so Ramadan styling is
  // preserved without threading `s` through the builders.
  AdaptiveStyle get style => AdaptiveStyle(context, false);

  Widget _buildGlassCard(AppLocalizations l10n) {
    final colors = context.colors;
    final typography = context.typography;
    return AuthGlassCard(
      child: AutofillGroup(
        child: Column(
          children: [
            // ── Segmented Sign In / New Account control ──
            Container(
              height: 52,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: colors.gold.withValues(alpha: 0.18)),
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
              duration: AppMotion.base,
              sizeCurve: AppMotion.emphasized,
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
                    onChanged: _clearError,
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
              onChanged: _clearError,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Password ─
            AuthField(
              ctrl: _passCtrl,
              hint: l10n.authPasswordHint,
              icon: Icons.lock_outline_rounded,
              style: style,
              isPassword: true,
              focusNode: _passFocus,
              isLast: true,
              onSubmit: _submitActiveTab,
              onChanged: _clearError,
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
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: _tabs.index == 0
                  ? Align(
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
                    )
                  : const SizedBox(width: double.infinity),
            ),

            if (_error != null) AuthBanner(message: _error!),
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
    );
  }

  Widget _buildSeparator(AppLocalizations l10n) {
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
            style: context.typography.bodySmall.copyWith(color: colors.textDim),
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

  Widget _buildGoogleBtn(AppLocalizations l10n) {
    return GoogleSignInButton(
      label: l10n.authGoogleSignInButton,
      onTap: _loading ? null : _signInGoogle,
    );
  }
}
