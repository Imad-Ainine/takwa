import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_success_overlay.dart';
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
        setState(() => _loading = false);
        await showAuthSuccess(context, label: l10n.updatePasswordSuccessMessage);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.auth,
            (route) => false,
          );
        }
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

  // Legacy AdaptiveStyle slot for AuthField; theming itself now resolves
  // from the active theme (which already carries Ramadan mode).
  AdaptiveStyle get s => AdaptiveStyle(context, false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return Stack(
      children: [
        AuthScaffold(
          showBack: false,
          children: [
            AuthGlassCard(
              child: Column(
                children: [
                  Center(
                    child: AuthEmblem.icon(
                      size: 84,
                      icon: Icons.lock_reset_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.updatePasswordTitle,
                    style: typography.displayLarge.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.updatePasswordSubtitle,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Password + confirm fields, grouped so a password
                  // manager can see them together.
                  AutofillGroup(
                    child: Column(
                      children: [
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
                        AnimatedSize(
                          duration: AppMotion.fast,
                          curve: AppMotion.standard,
                          alignment: Alignment.topCenter,
                          child: _passCtrl.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.sm,
                                  ),
                                  child: PasswordStrengthBar(
                                    strength: _passStrength,
                                    style: s,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: AppSpacing.lg),
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

                  if (_error != null) AuthBanner(message: _error!),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    onTap: _loading ? null : _updatePassword,
                    label: _loading
                        ? l10n.updatePasswordSavingButton
                        : l10n.updatePasswordSaveAndSignInButton,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // The recovery session only lives until the password changes —
            // give an explicit way out that doesn't strand the user.
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.auth,
                      (route) => false,
                    ),
                child: Text(
                  l10n.updatePasswordCancelButton,
                  style: typography.labelMedium.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
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
}
