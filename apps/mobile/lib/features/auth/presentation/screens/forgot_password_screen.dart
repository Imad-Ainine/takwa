import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/auth_field.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:takwa/features/auth/presentation/widgets/otp_input_field.dart';
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
  final _otpFieldKey = GlobalKey<OtpInputFieldState>();

  bool _loading = false;
  bool _codeSent = false;
  String? _error;
  String? _successMessage;

  int _resendCountdown = 0;
  Timer? _timer;

  /// The address the code went to — frozen at send time so editing the email
  /// field can't desync the "sent to" line from what the server has.
  String _sentTo = '';

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
    super.dispose();
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

  Future<void> _sendResetCode({bool fromResend = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (!fromResend) {
      if (email.isEmpty) {
        setState(() => _error = l10n.forgotPasswordEnterEmail);
        return;
      }
      if (!_isValidEmail(email)) {
        setState(() => _error = l10n.forgotPasswordInvalidEmailFormat);
        return;
      }
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
          _sentTo = email;
          _successMessage = l10n.forgotPasswordCodeSentMessage;
        });
        _startCountdown();
        _otpCtrl.clear();
        _otpFieldKey.currentState?.requestFocus();
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
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;
    final token = _otpCtrl.text.trim();

    if (token.isEmpty) {
      setState(() => _error = l10n.forgotPasswordEnterOtp);
      return;
    }
    if (token.length < 6) {
      setState(() => _error = l10n.otpEnterAllDigits);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: _sentTo,
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

  void _useAnotherEmail() {
    _timer?.cancel();
    setState(() {
      _codeSent = false;
      _resendCountdown = 0;
      _error = null;
      _successMessage = null;
      _otpCtrl.clear();
    });
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

  // Legacy AdaptiveStyle slot for AuthField; theming itself now resolves
  // from the active theme (which already carries Ramadan mode).
  AdaptiveStyle get s => AdaptiveStyle(context, false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        AuthScaffold(
          showBack: true,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.emphasized,
              child: _codeSent
                  ? _buildCodeStage(l10n, key: const ValueKey('code'))
                  : _buildEmailStage(l10n, key: const ValueKey('email')),
            ),
          ],
        ),
        if (_loading) const Positioned.fill(child: AuthLoadingOverlay()),
      ],
    );
  }

  Widget _stageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = context.colors;
    final typography = context.typography;
    return Column(
      children: [
        Center(child: AuthEmblem.icon(size: 84, icon: icon)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          title,
          style: typography.displayLarge.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildEmailStage(AppLocalizations l10n, {Key? key}) {
    return AuthGlassCard(
      key: key,
      child: Column(
        children: [
          _stageHeader(
            icon: Icons.lock_reset_rounded,
            title: l10n.forgotPasswordRecoverTitle,
            subtitle: l10n.forgotPasswordRecoverSubtitle,
          ),
          AuthField(
            ctrl: _emailCtrl,
            hint: l10n.authEmailHint,
            icon: Icons.alternate_email_rounded,
            style: s,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            isLast: true,
            onSubmit: () => _sendResetCode(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) AuthBanner(message: _error!),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            onTap: _loading ? null : () => _sendResetCode(),
            label: _loading
                ? l10n.forgotPasswordProcessing
                : l10n.forgotPasswordSendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStage(AppLocalizations l10n, {Key? key}) {
    final colors = context.colors;
    final typography = context.typography;
    return AuthGlassCard(
      key: key,
      child: Column(
        children: [
          _stageHeader(
            icon: Icons.mark_email_read_outlined,
            title: l10n.forgotPasswordEnterCodeTitle,
            subtitle: l10n.authOtpSentTo(maskEmail(_sentTo)),
          ),
          OtpInputField(
            key: _otpFieldKey,
            controller: _otpCtrl,
            hasError: _error != null,
            onCompleted: _verifyOtp,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.otpAutoVerifyNote,
            style: typography.caption.copyWith(color: colors.textDim),
            textAlign: TextAlign.center,
          ),
          if (_error != null) AuthBanner(message: _error!),
          if (_successMessage != null && _error == null)
            AuthBanner(
              message: _successMessage!,
              kind: AuthBannerKind.success,
            ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            onTap: _loading ? null : _verifyOtp,
            label: _loading
                ? l10n.forgotPasswordProcessing
                : l10n.forgotPasswordVerifyAndContinue,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_resendCountdown > 0)
            Text(
              l10n.forgotPasswordResendCountdown(_resendCountdown.toString()),
              style: typography.bodySmall.copyWith(color: colors.textDim),
            )
          else
            TextButton(
              onPressed: _loading
                  ? null
                  : () => _sendResetCode(fromResend: true),
              child: Text(
                l10n.forgotPasswordResendCode,
                style: typography.labelMedium.copyWith(
                  color: colors.goldText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          TextButton(
            onPressed: _loading ? null : _useAnotherEmail,
            child: Text(
              l10n.otpUseAnotherEmail,
              style: typography.labelMedium.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
