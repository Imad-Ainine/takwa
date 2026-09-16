import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _loading = false;
  bool _codeSent = false;
  String? _error;
  String? _successMessage;

  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_loading) return;
    if (_codeSent) {
      _verifyOtp();
    } else {
      _sendResetCode();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    ).hasMatch(email);
  }

  Future<void> _sendResetCode() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.forgotPasswordEnterEmail);
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = l10n.forgotPasswordInvalidEmailFormat);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'takwa://auth-callback',
      );
      if (mounted) {
        setState(() {
          _codeSent = true;
          _successMessage = l10n.forgotPasswordCodeSentMessage;
        });
        _startCountdown();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(l10n, e.message));
    } catch (e) {
      if (mounted) {
        setState(() => _error = l10n.forgotPasswordSendCodeFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    final token = _otpCtrl.text.trim();

    if (token.isEmpty) {
      setState(() => _error = l10n.forgotPasswordEnterOtp);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (res.session != null && mounted) {
        Navigator.pushReplacementNamed(context, Routes.updatePassword);
      } else {
        if (mounted) {
          setState(() => _error = l10n.forgotPasswordInvalidOtp);
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(l10n, e.message));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.forgotPasswordVerifyFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(AppLocalizations l10n, String message) {
    final msg = message.toLowerCase();
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return l10n.forgotPasswordRateLimited;
    }
    if (msg.contains('token') ||
        msg.contains('otp') ||
        msg.contains('invalid')) {
      return l10n.forgotPasswordTokenInvalidOrExpired;
    }
    if (msg.contains('user not found')) {
      return l10n.forgotPasswordNoAccountFound;
    }
    return l10n.forgotPasswordGenericError;
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
            child: Column(
              children: [
                // App bar with back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: s.gold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
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
                                _codeSent
                                    ? Icons.mark_email_read_outlined
                                    : Icons.lock_reset_rounded,
                                color: s.gold,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Title
                          Text(
                            _codeSent
                                ? l10n.forgotPasswordEnterCodeTitle
                                : l10n.forgotPasswordRecoverTitle,
                            style: s.amiri(32, weight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Subtitle
                          Text(
                            _codeSent
                                ? l10n.forgotPasswordEnterCodeSubtitle
                                : l10n.forgotPasswordRecoverSubtitle,
                            style: s.naskh(13, color: s.textSec),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),

                          // Email + OTP fields, grouped so a password
                          // manager can see them together.
                          AutofillGroup(
                            child: Column(
                              children: [
                                AuthField(
                                  ctrl: _emailCtrl,
                                  hint: l10n.authEmailHint,
                                  icon: Icons.alternate_email_rounded,
                                  style: s,
                                  keyboardType: TextInputType.emailAddress,
                                  focusNode: _emailFocus,
                                  isLast: !_codeSent,
                                  onSubmit: !_codeSent ? _submit : null,
                                  onChanged: (_) {
                                    if (_error != null) {
                                      setState(() => _error = null);
                                    }
                                  },
                                ),

                                // OTP field (shown when code is sent)
                                if (_codeSent) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  AuthField(
                                    ctrl: _otpCtrl,
                                    hint: l10n.forgotPasswordOtpHint,
                                    icon: Icons.pin_outlined,
                                    style: s,
                                    keyboardType: TextInputType.number,
                                    focusNode: _otpFocus,
                                    isLast: true,
                                    onSubmit: _submit,
                                    autofillHints: const [AutofillHints.oneTimeCode],
                                    onChanged: (_) {
                                      if (_error != null) {
                                        setState(() => _error = null);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Success Message Banner
                          if (_successMessage != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: Colors.greenAccent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.greenAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style: s.naskh(
                                        12,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Error Banner
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
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
                                      style: s.naskh(
                                        12,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Main Action Button
                          PrimaryButton(
                            onTap: _loading ? null : _submit,
                            label: _loading
                                ? l10n.forgotPasswordProcessing
                                : (_codeSent
                                      ? l10n.forgotPasswordVerifyAndContinue
                                      : l10n.forgotPasswordSendCode),
                          ),

                          // Resend Code or Change Email
                          if (_codeSent) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_resendCountdown > 0)
                                  Text(
                                    l10n.forgotPasswordResendCountdown(
                                      _resendCountdown.toString(),
                                    ),
                                    style: s.naskh(12, color: s.textDim),
                                  )
                                else
                                  TextButton(
                                    onPressed: _loading ? null : _sendResetCode,
                                    child: Text(
                                      l10n.forgotPasswordResendCode,
                                      style: s.naskh(
                                        12,
                                        color: s.gold,
                                        weight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
