import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/payments/chargily_service.dart';
import 'package:takwa/core/payments/payment_config.dart';
import 'package:takwa/core/payments/subscription_store.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// CIB / Edahabia payment via Chargily Pay V2 hosted checkout.
///
/// Flow: create checkout (server-to-server call with the Chargily token) →
/// open the returned `checkout_url` in an in-app browser → Chargily
/// redirects the browser to `takwa://payment-*`, which returns the user to
/// this screen → poll `GET /checkouts/{id}` until the status leaves
/// `pending` (a redirect alone is never treated as proof of payment).
class ChargilyPaymentScreen extends ConsumerStatefulWidget {
  /// `cib` or `edahabia` — selects the card network preselected on the
  /// hosted page.
  final String paymentMethod;

  const ChargilyPaymentScreen({super.key, this.paymentMethod = 'edahabia'});

  @override
  ConsumerState<ChargilyPaymentScreen> createState() =>
      _ChargilyPaymentScreenState();
}

enum _Stage { creating, awaiting, verifying, paid, failed, canceled, error }

class _ChargilyPaymentScreenState extends ConsumerState<ChargilyPaymentScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);
  static const _pollBudget = Duration(minutes: 3);

  _Stage _stage = _Stage.creating;
  ChargilyCheckout? _checkout;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _createCheckout());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Coming back from the browser: re-check immediately instead of waiting
  /// for the (possibly expired) polling budget.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _stage == _Stage.awaiting &&
        _checkout != null) {
      _verifyNow();
    }
  }

  Future<void> _createCheckout() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _stage = _Stage.creating;
      _errorMessage = null;
    });
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final checkout = await ChargilyService().createCheckout(
        paymentMethod: widget.paymentMethod,
        description: l10n.paymentChargilyDescription,
        // Chargily rejects custom-scheme callbacks; the web hop bounces
        // the browser back into the app after the card attempt.
        successUrl: ChargilyConfig.webRedirectUrl(
          'takwa://payment-success',
          locale: locale,
        ),
        failureUrl: ChargilyConfig.webRedirectUrl(
          'takwa://payment-failure',
          locale: locale,
        ),
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        _checkout = checkout;
        _stage = _Stage.awaiting;
      });
      await _openCheckoutPage(checkout.checkoutUrl);
      if (mounted && _stage == _Stage.awaiting) _startPolling();
    } catch (e, st) {
      AppLogger.warning('Chargily createCheckout failed', e, st);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        // A stalled socket is the usual failure on mobile data, and
        // "TimeoutException after 0:00:20.000000: Future not completed" tells
        // the user nothing they can act on.
        _errorMessage = e is TimeoutException || e is SocketException
            ? l10n.paymentNetworkError
            : '$e';
      });
    }
  }

  /// Open the hosted page as a Custom Tab; devices without a Custom Tabs
  /// provider (or where the tab silently fails) fall back to the external
  /// browser so the checkout is always reachable.
  Future<void> _openCheckoutPage(Uri url) async {
    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
      ).timeout(const Duration(seconds: 10));
      if (opened) return;
      throw Exception('no in-app browser available');
    } catch (e, st) {
      AppLogger.warning(
        'in-app checkout tab failed, opening externally',
        e,
        st,
      );
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e2, st2) {
        AppLogger.warning('Chargily checkout launch failed', e2, st2);
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
    final deadline = DateTime.now().add(_pollBudget);
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      final checkout = _checkout;
      if (checkout == null || DateTime.now().isAfter(deadline)) {
        timer.cancel();
        return;
      }
      try {
        final fresh = await ChargilyService().fetchCheckout(checkout.id);
        if (!mounted) return;
        if (fresh.status != 'pending' && fresh.status != 'processing') {
          timer.cancel();
          await _onStatusResolved(fresh);
        }
      } catch (e) {
        // Transient polling failure: keep trying until the budget expires.
        AppLogger.warning('Chargily poll failed', e, null);
      }
    });
  }

  Future<void> _onStatusResolved(ChargilyCheckout checkout) async {
    final stage = switch (checkout.status) {
      'paid' => _Stage.paid,
      'canceled' => _Stage.canceled,
      _ => _Stage.failed,
    };
    if (stage == _Stage.paid) {
      await _recordPayment(checkout, status: 'paid');
    }
    if (!mounted) return;
    setState(() => _stage = stage);
  }

  Future<void> _recordPayment(
    ChargilyCheckout checkout, {
    required String status,
  }) async {
    await ref
        .read(subscriptionStoreProvider)
        .recordPayment(
          SupportPayment(
            channel: SupportChannel.chargily,
            checkoutId: checkout.id,
            status: status,
            amountMinor: ChargilyConfig.subscriptionAmountCentime,
            currency: 'dzd',
            at: DateTime.now(),
          ),
        );
  }

  /// "I have completed the payment" — manual re-check when the user came
  /// back to the app without the browser following the redirect (some
  /// Android browsers ignore custom-scheme redirects).
  Future<void> _verifyNow() async {
    final checkout = _checkout;
    if (checkout == null) return;
    setState(() => _stage = _Stage.verifying);
    try {
      final fresh = await ChargilyService().fetchCheckout(checkout.id);
      if (!mounted) return;
      if (fresh.status == 'pending' || fresh.status == 'processing') {
        setState(() => _stage = _Stage.awaiting);
        _startPolling();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.paymentStillPending),
          ),
        );
        return;
      }
      await _onStatusResolved(fresh);
    } catch (e, st) {
      AppLogger.warning('Chargily verifyNow failed', e, st);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.paymentMethod == 'cib'
            ? l10n.paymentChargilyCibTitle
            : l10n.paymentMethodEdahabiaTitle,
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
    _Stage.paid => context.colors.successText,
    _Stage.failed ||
    _Stage.canceled ||
    _Stage.error => context.colors.dangerText,
    _ => context.colors.gold,
  };

  Widget _buildIcon() {
    final (icon, bg) = switch (_stage) {
      _Stage.paid => (Icons.check_circle_rounded, context.colors.successDim),
      _Stage.failed ||
      _Stage.canceled ||
      _Stage.error => (Icons.error_outline_rounded, context.colors.dangerDim),
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
                  _stage == _Stage.canceled ||
                  _stage == _Stage.error
              ? context.colors.dangerText
              : context.colors.gold,
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_stage) {
    _Stage.creating => l10n.paymentCreatingCheckout,
    _Stage.awaiting => l10n.paymentAwaitingTitle,
    _Stage.verifying => l10n.paymentVerifyingTitle,
    _Stage.paid => l10n.paymentSuccessTitle,
    _Stage.failed => l10n.paymentFailedTitle,
    _Stage.canceled => l10n.paymentCanceledTitle,
    _Stage.error => l10n.paymentErrorTitle,
  };

  String _subtitle(AppLocalizations l10n) => switch (_stage) {
    _Stage.creating => l10n.paymentCreatingCheckoutSubtitle,
    _Stage.awaiting => l10n.paymentAwaitingSubtitle,
    _Stage.verifying => l10n.paymentVerifyingTitle,
    _Stage.paid => l10n.paymentSuccessSubtitle,
    _Stage.failed => l10n.paymentFailedSubtitle,
    _Stage.canceled => l10n.paymentCanceledSubtitle,
    _Stage.error => l10n.paymentErrorSubtitle,
  };

  Widget _buildActions(AppLocalizations l10n) {
    final checkout = _checkout;
    switch (_stage) {
      case _Stage.creating:
      case _Stage.verifying:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: TakwaLoadingIndicator(),
        );
      case _Stage.awaiting:
        return Column(
          children: [
            if (checkout != null)
              PrimaryButton(
                label: l10n.paymentOpenCheckoutAgain,
                icon: Icons.public_rounded,
                onTap: () => _openCheckoutPage(checkout.checkoutUrl),
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
      case _Stage.paid:
        return PrimaryButton(
          label: l10n.paymentDoneButton,
          onTap: () => Navigator.pop(context),
        );
      case _Stage.failed:
      case _Stage.canceled:
        return Column(
          children: [
            PrimaryButton(
              label: l10n.paymentRetryButton,
              icon: Icons.refresh_rounded,
              onTap: _createCheckout,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.paymentDoneButton,
              isOutline: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      case _Stage.error:
        return Column(
          children: [
            PrimaryButton(
              label: l10n.paymentRetryButton,
              icon: Icons.refresh_rounded,
              onTap: _createCheckout,
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
