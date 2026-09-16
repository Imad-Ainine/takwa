import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/l10n/app_localizations.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();
  bool _loading = false;
  String? _error;
  double _passStrength = 0;

  @override
  void initState() {
    super.initState();
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
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (password.isEmpty) {
      setState(() => _error = l10n.updatePasswordEnterNew);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = l10n.authErrorPasswordTooShort);
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = l10n.updatePasswordMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.updatePasswordSuccessMessage),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.auth,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = _mapAuthError(l10n, e.message));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = l10n.updatePasswordUnexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _mapAuthError(AppLocalizations l10n, String message) {
    final msg = message.toLowerCase();
    if (msg.contains('same password')) {
      return l10n.updatePasswordSameAsOld;
    }
    if (msg.contains('password should')) {
      return l10n.updatePasswordMinLength;
    }
    if (msg.contains('session')) {
      return l10n.updatePasswordSessionExpired;
    }
    return l10n.updatePasswordGenericFailure;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final s = AdaptiveStyle(context, isRamadan);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [s.card, s.bg],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: s.gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: s.gold.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: s.gold,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Title
                    Text(
                      l10n.updatePasswordTitle,
                      style: s.amiri(32, weight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    Text(
                      l10n.updatePasswordSubtitle,
                      style: s.naskh(13, color: s.textSec),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Password + confirm fields, grouped so a password
                    // manager can see them together.
                    AutofillGroup(
                      child: Column(
                        children: [
                    // Password Field
                    AuthField(
                      ctrl: _passCtrl,
                      hint: l10n.updatePasswordNewHint,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      style: s,
                      focusNode: _passFocus,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),

                    // Strength bar
                    if (_passCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: PasswordStrengthBar(
                          strength: _passStrength,
                          style: s,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Confirm Password Field
                    AuthField(
                      ctrl: _confirmPassCtrl,
                      hint: l10n.updatePasswordConfirmHint,
                      icon: Icons.lock_clock_outlined,
                      isPassword: true,
                      style: s,
                      focusNode: _confirmPassFocus,
                      isLast: true,
                      onSubmit: _loading ? null : _updatePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                        ],
                      ),
                    ),

                    // Error banner
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: s.naskh(12, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),

                    // Submit Button
                    PrimaryButton(
                      onTap: _loading ? null : _updatePassword,
                      label: _loading
                          ? l10n.updatePasswordSavingButton
                          : l10n.updatePasswordSaveAndSignInButton,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
