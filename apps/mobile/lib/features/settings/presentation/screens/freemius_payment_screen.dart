import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/payments/entitlement_providers.dart';
import 'package:takwa/core/payments/freemius_service.dart';
import 'package:takwa/core/payments/payment_config.dart';
import 'package:takwa/core/payments/premium_entitlement.dart';
import 'package:takwa/core/payments/subscription_store.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/supabase_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Visa / Mastercard support via the Freemius hosted checkout.
///
/// Flow: ask the Takwa web proxy for a checkout session (authenticated with
/// the Supabase access token, so the purchase is tied to this account) →
/// open the returned URL in an in-app browser → Freemius redirects the
/// browser back through `takwa://payment-*` → poll OUR entitlement row (not
/// Freemius directly) until the signed webhook lands the purchase. The
/// redirect alone is never treated as proof of payment.
class FreemiusPaymentScreen extends ConsumerStatefulWidget {
  const FreemiusPaymentScreen({
    super.key,
    this.planId,
    this.entitlementFetcher,
  });

  /// Null = the proxy's default monthly plan.
  final String? planId;

  /// Injectable for widget tests; production reads the server entitlement.
  @visibleForTesting
  final Future<PremiumEntitlement?> Function(String userId)? entitlementFetcher;

  @override
  ConsumerState<FreemiusPaymentScreen> createState() =>
      _FreemiusPaymentScreenState();
}

enum _Stage { auth, creating, awaiting, verifying, active, failed, error }

class _FreemiusPaymentScreenState extends ConsumerState<FreemiusPaymentScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);
  static const _pollBudget = Duration(minutes: 4);

  _Stage _stage = _Stage.creating;
  FreemiusSession? _session;
  String? _errorMessage;
  Timer? _pollTimer;
  DateTime? _pollDeadline;

  Future<PremiumEntitlement?> _fetchEntitlement(String userId) =>
      widget.entitlementFetcher?.call(userId) ??
      const PremiumEntitlementRepository().fetch(userId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Coming back from the browser: check the entitlement immediately.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stage == _Stage.awaiting) {
      _verifyNow();
    }
  }

  Future<void> _start() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _stage = _Stage.auth);
      return;
    }
    await _createCheckout();
  }

  Future<void> _createCheckout() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _stage = _Stage.creating;
      _errorMessage = null;
    });
    try {
      final locale = Localizations.localeOf(context).languageCode;
      var token = SupabaseConfig.client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) {
        final refreshed = await SupabaseConfig.client.auth.refreshSession();
        token = refreshed.session?.accessToken ?? '';
      }
      final created = await FreemiusService().createCheckout(
        accessToken: token,
        planId: widget.planId,
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        _session = created;
        _stage = _Stage.awaiting;
      });
      await _openCheckoutPage(created.checkoutUrl);
      if (mounted && _stage == _Stage.awaiting) _startPolling();
    } catch (e, st) {
      AppLogger.warning('Freemius createCheckout failed', e, st);
      if (!mounted) return;
      setState(() {
        _stage = e is FreemiusException && e.isSignInRequired
            ? _Stage.auth
            : _Stage.error;
        _errorMessage = e is TimeoutException || e is SocketException
            ? l10n.paymentNetworkError
            : '$e';
      });
    }
  }

  /// Open the hosted page as a Custom Tab, with the same external-browser
  /// fallback the Chargily screen uses.
  Future<void> _openCheckoutPage(Uri url) async {
    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
      ).timeout(const Duration(seconds: 10));
      if (opened) return;
      throw Exception('no in-app browser available');
    } catch (e, st) {
      AppLogger.warning('in-app checkout tab failed, opening externally', e, st);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e2, st2) {
        AppLogger.warning('Freemius checkout launch failed', e2, st2);
        if (!mounted) return;
        setState(() {
          _stage = _Stage.error;
          _errorMessage = '$e2';
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollDeadline = DateTime.now().add(_pollBudget);
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      if (_pollDeadline == null || DateTime.now().isAfter(_pollDeadline!)) {
        timer.cancel();
        return;
      }
      try {
        await _checkEntitlement();
      } catch (e) {
        // Transient polling failure: keep trying until the budget expires.
        AppLogger.warning('Freemius entitlement poll failed', e, null);
      }
    });
  }

  Future<void> _checkEntitlement() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final entitlement = await _fetchEntitlement(user.id);
    if (!mounted) return;
    if (entitlement != null && entitlement.isActiveAt(DateTime.now())) {
      _pollTimer?.cancel();
      await _onPaymentConfirmed(entitlement);
    } else if (entitlement != null &&
        (entitlement.status == 'past_due' ||
            entitlement.status == 'refunded')) {
      _pollTimer?.cancel();
      if (!mounted) return;
      setState(() => _stage = _Stage.failed);
    }
  }

  Future<void> _onPaymentConfirmed(PremiumEntitlement entitlement) async {
    await ref.read(subscriptionStoreProvider).recordPayment(
      SupportPayment(
        channel: SupportChannel.freemius,
        checkoutId: entitlement.planId ?? _session?.planId,
        status: 'paid',
        amountMinor: (FreemiusConfig.monthlyUsd * 100).round(),
        currency: FreemiusConfig.currencyCode,
        at: DateTime.now(),
      ),
    );
    ref.invalidate(premiumEntitlementProvider);
    if (!mounted) return;
    setState(() => _stage = _Stage.active);
  }

  /// "I have completed the payment" — re-check the entitlement after the
  /// user returns without the browser following the redirect, and keep
  /// polling a while (the webhook may simply be a few seconds behind).
  Future<void> _verifyNow() async {
    setState(() => _stage = _Stage.verifying);
    try {
      await _checkEntitlement();
    } catch (e, st) {
      AppLogger.warning('Freemius verifyNow failed', e, st);
    }
    if (!mounted) return;
    if (_stage == _Stage.verifying) {
      setState(() => _stage = _Stage.awaiting);
      _startPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.paymentStillPending),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarWidget(
        title: l10n.paymentMethodVisaTitle,
        leading: CustomLeadingButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildIcon(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    _title(l10n),
                    textAlign: TextAlign.center,
                    style: context.typography.headingLarge.copyWith(
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _subtitle(l10n),
                    textAlign: TextAlign.center,
                    style: context.typography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  if (_stage == _Stage.error && _errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _ErrorBox(message: _errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildActions(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _titleColor => switch (_stage) {
    _Stage.active => context.colors.successText,
    _Stage.failed ||
    _Stage.error ||
    _Stage.auth => context.colors.dangerText,
    _ => context.colors.gold,
  };

  Widget _buildIcon() {
    final (icon, bg) = switch (_stage) {
      _Stage.active => (Icons.check_circle_rounded, context.colors.successDim),
      _Stage.failed ||
      _Stage.error ||
      _Stage.auth => (Icons.error_outline_rounded, context.colors.dangerDim),
      _ => (Icons.credit_card_rounded, context.colors.goldDim),
    };
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: context.colors.gold, width: 2),
          boxShadow: AppShadows.goldGlow,
        ),
        child: Icon(
          icon,
          size: 46,
          color:
              _stage == _Stage.failed ||
                  _stage == _Stage.error ||
                  _stage == _Stage.auth
              ? context.colors.dangerText
              : context.colors.gold,
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_stage) {
    _Stage.auth => l10n.paymentFreemiusSignInTitle,
    _Stage.creating => l10n.paymentCreatingCheckout,
    _Stage.awaiting => l10n.paymentAwaitingTitle,
    _Stage.verifying => l10n.paymentVerifyingTitle,
    _Stage.active => l10n.paymentSuccessTitle,
    _Stage.failed => l10n.paymentFailedTitle,
    _Stage.error => l10n.paymentErrorTitle,
  };

  String _subtitle(AppLocalizations l10n) => switch (_stage) {
    _Stage.auth => l10n.paymentFreemiusSignInSubtitle,
    _Stage.creating => l10n.paymentCreatingFreemiusSubtitle,
    _Stage.awaiting => l10n.paymentAwaitingFreemiusSubtitle,
    _Stage.verifying => l10n.paymentVerifyingTitle,
    _Stage.active => l10n.paymentSuccessSubtitle,
    _Stage.failed => l10n.paymentFailedSubtitle,
    _Stage.error => l10n.paymentErrorSubtitle,
  };

  Widget _buildActions(AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.creating:
      case _Stage.verifying:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: TakwaLoadingIndicator(),
        );
      case _Stage.auth:
        return Column(
          children: [
            PrimaryButton(
              label: l10n.paymentSignInButton,
              icon: Icons.person_rounded,
              onTap: () => Navigator.pushNamed(context, Routes.auth),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.guestGuardBackButton,
              isOutline: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      case _Stage.awaiting:
        final session = _session;
        return Column(
          children: [
            if (session != null)
              PrimaryButton(
                label: l10n.paymentOpenCheckoutAgain,
                icon: Icons.public_rounded,
                onTap: () => _openCheckoutPage(session.checkoutUrl),
              ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.paymentIAmDone,
              icon: Icons.done_rounded,
              isOutline: true,
              onTap: _verifyNow,
            ),
          ],
        );
      case _Stage.active:
        return PrimaryButton(
          label: l10n.paymentDoneButton,
          onTap: () => Navigator.pop(context),
        );
      case _Stage.failed:
      case _Stage.error:
        return Column(
          children: [
            PrimaryButton(
              label: l10n.paymentRetryButton,
              icon: Icons.refresh_rounded,
              onTap: _start,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.paymentDoneButton,
              isOutline: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
    }
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.dangerDim,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: context.typography.bodySmall.copyWith(color: colors.dangerText),
      ),
    );
  }
}
